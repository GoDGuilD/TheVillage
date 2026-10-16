# File: Player.gd
# Description: Top-down Joe: ALttP walking (facing rule, corner nudge, ledge hops), slash, charge + spin attack, shield block, lift/carry/throw, pickups, hurt and death.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 2.3.0
class_name Player
extends CharacterBody2D
## The node origin is Joe's feet. Only a small box around the feet collides with the world (as in ALttP),
## so his head can overlap the tile above a wall. Children are built in code in _ready() so the scene file
## stays a one-liner and every number comes from PlayerTuning.
##
## States: idle, walk, hop, attack, charge, spin, lift, carry, throw, hurt, dead.

signal health_changed(current: int, maximum: int)
signal died
signal talk_requested(target: Node2D)   # interact pressed facing a villager or sign (the World opens the box)
signal item_collected(kind: String)       # touched a pickup the World handles (heart piece, container, key)

const SPRITE_DIR := "res://assets/sprites/joe/"
const SHADOW_TEX := preload("res://assets/sprites/joe/joe_shadow.png")
const THROWN_SCRIPT := preload("res://src/world/Thrown.gd")
const FEET_BOX := Vector2(10, 6)          # world collision box (px) centred just above the feet
const HURT_BOX := Vector2(12, 16)         # area enemies' hit boxes must touch to hurt Joe
# Physics layers (see project.godot [layer_names]); values are bit values, not indices.
const LAYER_WORLD := 1
const LAYER_PLAYER := 2
const LAYER_PLAYER_HITBOX := 8
const LAYER_ENEMY_HITBOX := 16
const LAYER_PLAYER_HURTBOX := 32
const LAYER_PROPS := 128
const SWORD_TIP := 18.0                   # px from the body centre to the held sword's tip (glint position)
const DROP_TRAVEL := 2.0                  # a carried object dropped by a hit breaks right at Joe's feet

# Cardinal facing; diagonal movement keeps the previous facing when it is one of the two components.
var facing := Vector2i.DOWN
var health: HealthComponent
var sprite: AnimatedSprite2D
var sword: HitBox
var spin_box: HitBox
var hurt_box: HurtBox
var fsm: StateMachine
var charged := false                      # spin attack ready (sword glinting)
var carrying := ""                        # kind of the lifted object ("pot", "bush") or ""
var carried_sprite: Sprite2D
var held_sprite: Sprite2D                 # a found item held over his head (state "hold")
var used_item := ""                       # the Y-item used last (tests)

var _sword_shape: CollisionShape2D
var _manifest: Dictionary = {}
var _attack_buffer := 0.0
var _hurt_left := 0.0
var _iframes_left := 0.0
var _frozen_left := 0.0
var _charge_t := 0.0
var _glint_t := 0.0
var _timer := 0.0                         # generic countdown for timed states (spin, lift, throw)
var _carried_tex: Texture2D
var _knockback := Vector2.ZERO
var _hop_from := Vector2.ZERO
var _hop_to := Vector2.ZERO
var _input_override = null                # tests may set a Vector2 here instead of reading the keyboard


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = LAYER_PLAYER
	collision_mask = LAYER_WORLD | LAYER_PROPS
	_build_children()
	health.max_health = PlayerTuning.MAX_HP
	health.current_health = PlayerTuning.MAX_HP
	health.health_changed.connect(func(c: int, m: int) -> void: health_changed.emit(c, m))
	health.died.connect(_on_died)
	fsm.init(self, "idle")


# Build collision, shadow, sprite, sword + spin hit boxes, hurt box, health and state machine.
func _build_children() -> void:
	var feet := CollisionShape2D.new()
	var feet_rect := RectangleShape2D.new()
	feet_rect.size = FEET_BOX
	feet.shape = feet_rect
	feet.position = Vector2(0, -FEET_BOX.y / 2.0)
	add_child(feet)

	var shadow := Sprite2D.new()
	shadow.name = "Shadow"
	shadow.texture = SHADOW_TEX
	shadow.position = Vector2(0, -1)
	add_child(shadow)

	sprite = AnimatedSprite2D.new()
	sprite.name = "Sprite"
	sprite.sprite_frames = SpriteStrips.load_joe(SPRITE_DIR)
	var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SPRITE_DIR + "joe_animations.json"))
	_manifest = m["anims"]
	var fs: Array = m["frame_size"]
	var feet_px: Array = m["feet"]
	sprite.offset = Vector2(0, float(fs[1]) / 2.0 - float(feet_px[1]))
	HitFlash.attach(sprite)
	add_child(sprite)
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation_finished.connect(_on_animation_finished)

	sword = HitBox.new()
	sword.name = "Sword"
	sword.collision_layer = LAYER_PLAYER_HITBOX
	sword.collision_mask = 0
	sword.damage = PlayerTuning.SWORD_DAMAGE
	sword.knockback = Vector2(PlayerTuning.SWORD_KNOCKBACK, 0)
	sword.monitorable = false
	_sword_shape = CollisionShape2D.new()
	_sword_shape.shape = RectangleShape2D.new()
	sword.add_child(_sword_shape)
	add_child(sword)

	spin_box = HitBox.new()
	spin_box.name = "Spin"
	spin_box.collision_layer = LAYER_PLAYER_HITBOX
	spin_box.collision_mask = 0
	spin_box.damage = PlayerTuning.SPIN_DAMAGE
	spin_box.knockback = Vector2(PlayerTuning.SPIN_KNOCKBACK, 0)
	spin_box.monitorable = false
	var ss := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PlayerTuning.SPIN_RADIUS
	ss.shape = circle
	ss.position = PlayerTuning.BODY_CENTER
	spin_box.add_child(ss)
	add_child(spin_box)

	hurt_box = HurtBox.new()
	hurt_box.name = "HurtBox"
	hurt_box.collision_layer = LAYER_PLAYER_HURTBOX
	hurt_box.collision_mask = LAYER_ENEMY_HITBOX
	var hs := CollisionShape2D.new()
	hs.name = "Shape"
	var hr := RectangleShape2D.new()
	hr.size = HURT_BOX
	hs.shape = hr
	hs.position = PlayerTuning.BODY_CENTER
	hurt_box.add_child(hs)
	add_child(hurt_box)
	hurt_box.hurt.connect(_on_hurt)

	health = HealthComponent.new()
	health.name = "Health"
	add_child(health)

	fsm = StateMachine.new()
	fsm.name = "StateMachine"
	add_child(fsm)


func _physics_process(delta: float) -> void:
	# Hit-stop: pause the state machine and the animation for a few frames.
	if _frozen_left > 0.0:
		_frozen_left -= delta
		fsm.set_physics_process(false)
		sprite.speed_scale = 0.0
		return
	fsm.set_physics_process(true)
	sprite.speed_scale = 1.0
	_attack_buffer = maxf(0.0, _attack_buffer - delta)
	if _iframes_left > 0.0:
		_iframes_left -= delta
		# Blink: hide on alternate half-periods; always visible again when invincibility ends.
		sprite.visible = _iframes_left <= 0.0 or int(_iframes_left * PlayerTuning.BLINK_HZ * 2.0) % 2 == 0
		if _iframes_left <= 0.0:
			hurt_box.recheck()               # still touching an enemy? take the next hit now


# --- input helpers --------------------------------------------------------------

func _move_input() -> Vector2:
	if _input_override != null:
		return _input_override
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


# ALttP facing rule: keep the current facing while it is still one of the pressed directions,
# otherwise face along the dominant axis (vertical wins a perfect diagonal from a standstill).
func _update_facing(dir: Vector2) -> void:
	var h := signi(roundi(dir.x * 10.0))
	var v := signi(roundi(dir.y * 10.0))
	if h == 0 and v == 0:
		return
	if (facing.x != 0 and facing.x == h) or (facing.y != 0 and facing.y == v):
		return
	if v != 0 and absf(dir.y) >= absf(dir.x):
		facing = Vector2i(0, v)
	else:
		facing = Vector2i(h, 0)


func _dir_name() -> String:
	if facing.y > 0:
		return "down"
	if facing.y < 0:
		return "up"
	return "side"


func _facing_key() -> String:
	if facing.x > 0:
		return "right"
	if facing.x < 0:
		return "left"
	return _dir_name()


func _play(base: String) -> void:
	sprite.flip_h = facing.x < 0
	var anim := "%s_%s" % [base, _dir_name()]
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)


# Walk at `speed`; if a single-axis step is blocked near an obstacle's corner, slide around it.
func _walk(dir: Vector2, delta: float, speed: float = PlayerTuning.WALK_SPEED) -> void:
	velocity = dir.normalized() * speed if dir != Vector2.ZERO else Vector2.ZERO
	var before := global_position
	move_and_slide()
	var axis_only := (dir.x == 0.0) != (dir.y == 0.0)
	if axis_only and get_slide_collision_count() > 0 and global_position.distance_to(before) < 0.01:
		_try_corner_nudge(dir.normalized(), delta)


func _try_corner_nudge(step: Vector2, delta: float) -> void:
	var perp := Vector2(step.y, step.x).abs()
	for k in range(1, PlayerTuning.CORNER_NUDGE_PX + 1):
		for side in [-1.0, 1.0]:
			var off: Vector2 = perp * side * float(k)
			if not test_move(global_transform.translated(off), step):
				move_and_collide(perp * side * PlayerTuning.NUDGE_SPEED * delta)
				return


# Item button with a Y-item equipped: use it (state "use"). Returns true if it did.
func _try_item() -> bool:
	if not Input.is_action_just_pressed("item") or GameState.equipped == "":
		return false
	fsm.transition_to("use")
	return true


func _wants_attack() -> bool:
	return Input.is_action_just_pressed("attack") or _attack_buffer > 0.0


# Interact in front of Joe: talking to a villager / reading a sign wins over lifting.
# Returns true if it started a lift or a conversation.
func _try_lift() -> bool:
	if not Input.is_action_just_pressed("interact"):
		return false
	var talker := talkable_in_front()
	if talker != null:
		velocity = Vector2.ZERO
		talk_requested.emit(talker)
		return true
	var target := liftable_in_front()
	if target == null:
		return false
	var info: Dictionary = target.lift()
	carrying = String(info["kind"])
	_carried_tex = info["texture"]
	fsm.transition_to("lift")
	return true


# The nearest liftable node (pot, bush) right in front of Joe's feet, or null.
func liftable_in_front() -> Node2D:
	var grab := global_position + Vector2(facing) * PlayerTuning.LIFT_REACH + PlayerTuning.LIFT_GRAB_OFFSET
	var best: Node2D = null
	var best_d := PlayerTuning.LIFT_RADIUS
	for n in get_tree().get_nodes_in_group("liftable"):
		var node := n as Node2D
		if node == null or not node.call("can_lift"):
			continue
		var d := node.global_position.distance_to(grab)
		if d <= best_d:
			best = node
			best_d = d
	return best


# The nearest villager or sign whose talk point is right in front of Joe, or null.
func talkable_in_front() -> Node2D:
	var probe := global_position + PlayerTuning.TALK_PROBE_UP + Vector2(facing) * PlayerTuning.TALK_REACH
	var best: Node2D = null
	var best_d := PlayerTuning.TALK_RADIUS
	for n in get_tree().get_nodes_in_group("talkable"):
		var node := n as Node2D
		if node == null or not node.is_inside_tree():
			continue
		var d: float = (node.call("talk_point") as Vector2).distance_to(probe)
		if d <= best_d:
			best = node
			best_d = d
	return best


# --- states: moving ----------------------------------------------------------------

func state_idle_enter() -> void:
	velocity = Vector2.ZERO
	_play("idle")


func state_idle_update(delta: float) -> void:
	if _wants_attack():
		fsm.transition_to("attack")
		return
	if _try_lift() or _try_item():
		return
	if _move_input() != Vector2.ZERO:
		fsm.transition_to("walk")
		return
	_walk(Vector2.ZERO, delta)


func state_walk_update(delta: float) -> void:
	if _wants_attack():
		fsm.transition_to("attack")
		return
	if _try_lift() or _try_item():
		return
	var dir := _move_input()
	if dir == Vector2.ZERO:
		fsm.transition_to("idle")
		return
	_update_facing(dir)
	_play("walk")
	_walk(dir, delta)
	# Walking south into a ledge hops down it (ALttP); ledges are solid from every other side.
	if dir.y > 0.0 and absf(dir.x) < PlayerTuning.HOP_MAX_SIDEWAYS and get_slide_collision_count() > 0 			and AreaBuilder.flag_at(get_tree(), global_position + Vector2(0, PlayerTuning.LEDGE_PROBE), "ledge"):
		fsm.transition_to("hop")


# Hop down a ledge: fly over its cells (no collision) to the first open cell below, in a little arc.
func state_hop_enter() -> void:
	facing = Vector2i.DOWN
	_hop_from = global_position
	var y := global_position.y + PlayerTuning.LEDGE_PROBE
	var guard := 0
	while AreaBuilder.flag_at(get_tree(), Vector2(global_position.x, y), "ledge") and guard < PlayerTuning.HOP_MAX_CELLS:
		y += AreaBuilder.TILE
		guard += 1
	var cell_top := floorf(y / AreaBuilder.TILE) * AreaBuilder.TILE
	_hop_to = Vector2(global_position.x, cell_top + PlayerTuning.HOP_LAND_INSET)
	_timer = PlayerTuning.HOP_TIME
	velocity = Vector2.ZERO
	_play("walk")
	sprite.pause()
	Audio.sfx("ledge_hop")


func state_hop_update(delta: float) -> void:
	_timer -= delta
	var t := clampf(1.0 - _timer / PlayerTuning.HOP_TIME, 0.0, 1.0)
	global_position = _hop_from.lerp(_hop_to, t)
	sprite.position.y = -PlayerTuning.HOP_HEIGHT * 4.0 * t * (1.0 - t)
	if _timer <= 0.0:
		fsm.transition_to("idle")


func state_hop_exit() -> void:
	sprite.position.y = 0.0
	global_position = _hop_to
	Audio.sfx("land")


func is_hopping() -> bool:
	return fsm.current_state == "hop"


# --- states: sword -------------------------------------------------------------------

func state_attack_enter() -> void:
	velocity = Vector2.ZERO
	_attack_buffer = 0.0
	_place_sword()
	sprite.flip_h = facing.x < 0
	sprite.play("attack_%s" % _dir_name())
	sprite.frame = 0
	Audio.sfx("sword_slash")
	_on_frame_changed()


func state_attack_update(_delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		_attack_buffer = PlayerTuning.ATTACK_BUFFER


func state_attack_exit() -> void:
	sword.set_active(false)


# Holding the button after a slash: the sword stays out, Joe shuffles with his facing locked, and after
# CHARGE_TIME the blade glints. Releasing a charged sword spins; releasing early just stops.
func state_charge_enter() -> void:
	_charge_t = 0.0
	_glint_t = 0.0
	charged = false
	sprite.flip_h = facing.x < 0
	sprite.play("charge_%s" % _dir_name())


func state_charge_update(delta: float) -> void:
	if not Input.is_action_pressed("attack"):
		fsm.transition_to("spin" if charged else "idle")
		return
	var dir := _move_input()
	_walk(dir, delta, PlayerTuning.CHARGE_WALK_SPEED)
	if dir == Vector2.ZERO:
		sprite.pause()
	elif not sprite.is_playing():
		sprite.play()
	_charge_t += delta
	if not charged and _charge_t >= PlayerTuning.CHARGE_TIME:
		charged = true
		Audio.sfx("charge_ready")
		_glint()
	elif charged:
		_glint_t += delta
		if _glint_t >= PlayerTuning.GLINT_EVERY:
			_glint_t = 0.0
			_glint()


func _glint() -> void:
	var tip := global_position + PlayerTuning.BODY_CENTER + Vector2(facing) * SWORD_TIP
	Juice.play_fx("glint", tip, get_parent())


func state_spin_enter() -> void:
	velocity = Vector2.ZERO
	charged = false
	sprite.flip_h = false                   # the spin strip is drawn for every direction already
	sprite.play("spin")
	var spin_info: Dictionary = _manifest.get("spin", {})
	var starts: Dictionary = spin_info.get("start", {})
	sprite.frame = int(starts.get(_facing_key(), 0))
	_timer = PlayerTuning.SPIN_TIME
	spin_box.set_active(true)
	Audio.sfx("sword_spin")


func state_spin_update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		fsm.transition_to("idle")


func state_spin_exit() -> void:
	spin_box.set_active(false)


# Orient the slash box in front of Joe for the current facing.
func _place_sword() -> void:
	var f := Vector2(facing)
	var rect := _sword_shape.shape as RectangleShape2D
	if facing.x != 0:
		rect.size = Vector2(PlayerTuning.SWORD_BOX_DEPTH, PlayerTuning.SWORD_BOX_WIDTH)
	else:
		rect.size = Vector2(PlayerTuning.SWORD_BOX_WIDTH, PlayerTuning.SWORD_BOX_DEPTH)
	_sword_shape.position = PlayerTuning.BODY_CENTER + f * PlayerTuning.SWORD_BOX_FRONT


# The sword only hurts during the manifest's hit window frames.
func _on_frame_changed() -> void:
	if fsm == null or fsm.current_state != "attack":
		return
	var info: Dictionary = _manifest.get(sprite.animation, {})
	var win: Array = info.get("hit_window", [])
	var live := win.size() == 2 and sprite.frame >= int(win[0]) and sprite.frame <= int(win[1])
	sword.set_active(live)


func _on_animation_finished() -> void:
	if fsm.current_state != "attack":
		return
	if _attack_buffer > 0.0:
		state_attack_enter()                   # chained slash: restart the attack without leaving the state
		return
	if Input.is_action_pressed("attack"):
		fsm.transition_to("charge")
		return
	fsm.transition_to("walk" if _move_input() != Vector2.ZERO else "idle")


# --- states: items ------------------------------------------------------------------------------

# Use the equipped Y-item (boomerang / bow / bombs / lantern) in the throw pose.
func state_use_enter() -> void:
	velocity = Vector2.ZERO
	_timer = PlayerTuning.USE_TIME
	sprite.flip_h = facing.x < 0
	sprite.play("throw_%s" % _dir_name())
	used_item = GameState.equipped
	ItemUse.use(self, used_item, _move_input())


func state_use_update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		fsm.transition_to("idle")


# Hold a found item over his head, facing the camera (ALttP's item-get pose). The World ends it.
func hold_up(texture: Texture2D) -> void:
	facing = Vector2i.DOWN
	fsm.transition_to("hold")
	if is_instance_valid(held_sprite):
		held_sprite.queue_free()
	held_sprite = Sprite2D.new()
	held_sprite.texture = texture
	held_sprite.position = Vector2(0, -PlayerTuning.HOLD_HEIGHT)
	held_sprite.z_index = 1
	add_child(held_sprite)


func end_hold() -> void:
	if is_instance_valid(held_sprite):
		held_sprite.queue_free()
	held_sprite = null
	if fsm.current_state == "hold":
		fsm.transition_to("idle")


func state_hold_enter() -> void:
	velocity = Vector2.ZERO
	sprite.flip_h = false
	sprite.play("carry_down")


func state_hold_update(_delta: float) -> void:
	pass


# --- states: lifting and throwing -------------------------------------------------------

func state_lift_enter() -> void:
	velocity = Vector2.ZERO
	_timer = PlayerTuning.LIFT_TIME
	carried_sprite = Sprite2D.new()
	carried_sprite.texture = _carried_tex
	carried_sprite.position = Vector2(Vector2(facing) * PlayerTuning.LIFT_REACH) + Vector2(0, -6)
	carried_sprite.z_index = 1
	add_child(carried_sprite)
	var tw := carried_sprite.create_tween()
	tw.tween_property(carried_sprite, "position", Vector2(0, -PlayerTuning.CARRY_HEIGHT), PlayerTuning.LIFT_TIME)
	sprite.flip_h = facing.x < 0
	sprite.play("lift_%s" % _dir_name())
	Audio.sfx("lift")


func state_lift_update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		fsm.transition_to("carry")


func state_carry_update(delta: float) -> void:
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("attack"):
		fsm.transition_to("throw")
		return
	var dir := _move_input()
	_update_facing(dir)
	_play("carry_walk" if dir != Vector2.ZERO else "carry")
	_walk(dir, delta)


func state_throw_enter() -> void:
	velocity = Vector2.ZERO
	_timer = PlayerTuning.THROW_TIME
	_release_carried(PlayerTuning.THROW_RANGE)
	sprite.flip_h = facing.x < 0
	sprite.play("throw_%s" % _dir_name())
	Audio.sfx("throw")


func state_throw_update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		fsm.transition_to("idle")


# Turn the carried object into a flying Thrown that travels `travel` px along the facing.
func _release_carried(travel: float) -> Node2D:
	if carrying == "":
		return null
	var t: CharacterBody2D = THROWN_SCRIPT.new()
	t.kind = carrying
	t.texture = _carried_tex
	t.direction = Vector2(facing)
	t.speed = PlayerTuning.THROW_SPEED
	t.travel = travel
	t.start_height = PlayerTuning.CARRY_HEIGHT
	t.damage = PlayerTuning.THROW_DAMAGE
	t.position = position
	get_parent().add_child(t)
	carrying = ""
	if is_instance_valid(carried_sprite):
		carried_sprite.queue_free()
	carried_sprite = null
	return t


# --- states: damage ---------------------------------------------------------------------

func state_hurt_enter() -> void:
	_hurt_left = PlayerTuning.HURT_TIME
	_play("hurt")


func state_hurt_update(delta: float) -> void:
	_hurt_left -= delta
	velocity = _knockback
	move_and_slide()
	if _hurt_left <= 0.0:
		_knockback = Vector2.ZERO
		fsm.transition_to("idle")


func state_dead_enter() -> void:
	velocity = Vector2.ZERO
	sword.set_active(false)
	spin_box.set_active(false)
	sprite.visible = true
	_iframes_left = 0.0
	_play("hurt")


func state_dead_update(_delta: float) -> void:
	pass


func is_invincible() -> bool:
	return _iframes_left > 0.0


func is_dead() -> bool:
	return fsm.current_state == "dead"


# Hit-stop hook used by Juice.hit_stop; the World also freezes Joe during screen scrolls and door fades.
func freeze(seconds: float) -> void:
	_frozen_left = maxf(_frozen_left, seconds)


func unfreeze() -> void:
	_frozen_left = 0.0


# The shield (always on Joe's arm) stops blockable hits coming at his front while he is not busy swinging.
func blocks_from(source_position: Vector2) -> bool:
	if not fsm.current_state in PlayerTuning.SHIELD_STATES:
		return false
	var to_src := source_position - (global_position + PlayerTuning.BODY_CENTER)
	if to_src.length() < 0.01:
		return false
	return to_src.normalized().dot(Vector2(facing)) >= PlayerTuning.SHIELD_DOT


func _on_hurt(damage: int, source_position: Vector2, _kb: Vector2) -> void:
	if is_dead():
		return
	var hit := hurt_box.last_hit
	if hit != null and hit.blockable and blocks_from(source_position):
		Audio.sfx("shield_block")
		Juice.play_fx("hit_spark", global_position + PlayerTuning.BODY_CENTER + Vector2(facing) * PlayerTuning.SHIELD_FX_OUT, get_parent())
		var owner_node := hit.get_parent()
		if owner_node != null and owner_node.has_method("deflect"):
			owner_node.deflect()
		return
	if is_invincible() or not health.is_alive():
		return
	if carrying != "":
		_release_carried(DROP_TRAVEL)       # a hit makes Joe drop what he carries
	health.take_damage(damage)
	if not health.is_alive():
		return                               # _on_died takes over
	Audio.sfx("hurt")
	Juice.shake(PlayerTuning.HURT_SHAKE.x, PlayerTuning.HURT_SHAKE.y)
	var away := (global_position + PlayerTuning.BODY_CENTER - source_position)
	_knockback = (away.normalized() if away.length() > 0.01 else -Vector2(facing)) * PlayerTuning.HURT_KNOCKBACK_SPEED
	_iframes_left = PlayerTuning.IFRAMES
	HitFlash.flash(sprite)
	fsm.transition_to("hurt")


func _on_died() -> void:
	Audio.sfx("player_die")
	fsm.transition_to("dead")
	died.emit()


# Back on his feet at `at` with full health (the field calls this after a death).
func revive(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	facing = Vector2i.DOWN
	health.heal(health.max_health)
	_iframes_left = 0.0
	sprite.visible = true
	fsm.transition_to("idle")


# Pickup contract (Pickup.gd calls this on touch).
func collect(kind: String) -> void:
	if kind == "heart":
		health.heal(PlayerTuning.HEART_HEAL)
		Audio.sfx("pickup_heart")
	elif GameState.GEM_VALUES.has(kind):
		GameState.add_gems(int(GameState.GEM_VALUES[kind]))
		Audio.sfx("pickup_gem")
	else:
		item_collected.emit(kind)            # heart piece / container / key: the World runs the item-get
