# File: Player.gd
# Description: Top-down Joe: 8-way walking with A Link to the Past facing rules and corner nudging, sword slashes, being hurt.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
class_name Player
extends CharacterBody2D
## The node origin is Joe's feet. Only a small box around the feet collides with the world (as in ALttP),
## so his head can overlap the tile above a wall. Children are built in code in _ready() so the scene file
## stays a one-liner and every number comes from PlayerTuning.

signal health_changed(current: int, maximum: int)
signal died

const SPRITE_DIR := "res://assets/sprites/joe/"
const SHADOW_TEX := preload("res://assets/sprites/joe/joe_shadow.png")
const FEET_BOX := Vector2(10, 6)          # world collision box (px) centred just above the feet
const HURT_BOX := Vector2(12, 16)         # area enemies' hit boxes must touch to hurt Joe
# Physics layers (see project.godot [layer_names]); values are bit values, not indices.
const LAYER_WORLD := 1
const LAYER_PLAYER := 2
const LAYER_PLAYER_HITBOX := 8
const LAYER_ENEMY_HITBOX := 16
const LAYER_PLAYER_HURTBOX := 32
const LAYER_CUTTABLE := 128

# Cardinal facing; diagonal movement keeps the previous facing when it is one of the two components.
var facing := Vector2i.DOWN
var health: HealthComponent
var sprite: AnimatedSprite2D
var sword: HitBox
var hurt_box: HurtBox
var fsm: StateMachine

var _sword_shape: CollisionShape2D
var _manifest: Dictionary = {}
var _attack_buffer := 0.0
var _hurt_left := 0.0
var _iframes_left := 0.0
var _knockback := Vector2.ZERO
var _input_override = null                # tests may set a Vector2 here instead of reading the keyboard


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = LAYER_PLAYER
	collision_mask = LAYER_WORLD | LAYER_CUTTABLE
	_build_children()
	health.max_health = PlayerTuning.MAX_HP
	health.current_health = PlayerTuning.MAX_HP
	health.health_changed.connect(func(c: int, m: int) -> void: health_changed.emit(c, m))
	health.died.connect(func() -> void: died.emit())
	fsm.init(self, "idle")


# Build collision, shadow, sprite, sword hit box, hurt box, health and state machine.
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


func _play(base: String) -> void:
	sprite.flip_h = facing.x < 0
	var anim := "%s_%s" % [base, _dir_name()]
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)


# Walk at full speed; if a single-axis step is blocked near an obstacle's corner, slide around it.
func _walk(dir: Vector2, delta: float) -> void:
	velocity = dir.normalized() * PlayerTuning.WALK_SPEED if dir != Vector2.ZERO else Vector2.ZERO
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


# --- states -----------------------------------------------------------------------

func state_idle_enter() -> void:
	velocity = Vector2.ZERO
	_play("idle")


func state_idle_update(delta: float) -> void:
	if _wants_attack():
		fsm.transition_to("attack")
		return
	var dir := _move_input()
	if dir != Vector2.ZERO:
		fsm.transition_to("walk")
		return
	_walk(Vector2.ZERO, delta)


func state_walk_update(delta: float) -> void:
	if _wants_attack():
		fsm.transition_to("attack")
		return
	var dir := _move_input()
	if dir == Vector2.ZERO:
		fsm.transition_to("idle")
		return
	_update_facing(dir)
	_play("walk")
	_walk(dir, delta)


func state_attack_enter() -> void:
	velocity = Vector2.ZERO
	_attack_buffer = 0.0
	_place_sword()
	sprite.flip_h = facing.x < 0
	sprite.play("attack_%s" % _dir_name())
	sprite.frame = 0
	_on_frame_changed()


func state_attack_update(_delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		_attack_buffer = PlayerTuning.ATTACK_BUFFER


func state_attack_exit() -> void:
	sword.set_active(false)


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


func _wants_attack() -> bool:
	return Input.is_action_just_pressed("attack") or _attack_buffer > 0.0


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
	fsm.transition_to("walk" if _move_input() != Vector2.ZERO else "idle")


# --- damage -----------------------------------------------------------------------

func is_invincible() -> bool:
	return _iframes_left > 0.0


func _on_hurt(damage: int, source_position: Vector2, _kb: Vector2) -> void:
	if is_invincible() or not health.is_alive():
		return
	health.take_damage(damage)
	var away := (global_position + PlayerTuning.BODY_CENTER - source_position)
	_knockback = (away.normalized() if away.length() > 0.01 else -Vector2(facing)) * PlayerTuning.HURT_KNOCKBACK_SPEED
	_iframes_left = PlayerTuning.IFRAMES
	HitFlash.flash(sprite)
	fsm.transition_to("hurt")
