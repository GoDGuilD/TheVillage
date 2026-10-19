# File: BaseEnemy.gd
# Description: Shared top-down enemy body: sprite pack, feet collision, hurt/contact boxes, knockback, hit flash, hit-stop, death puff and drops.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-22
# Version: 1.5.0
class_name BaseEnemy
extends CharacterBody2D
## Subclasses set the pack/stat variables in _init() and override _think(delta) (AI) and optionally _anim_base().
## Movement goes through _move(); while stunned or frozen the AI does not run. Like ALttP, enemies pass through
## Joe and each other (they only collide with the world and solid props) and hurt him by touching him.

signal defeated(at: Vector2)

const SPRITE_DIR := "res://assets/sprites/enemies/"
const PICKUP_SCRIPT := preload("res://src/world/Pickup.gd")
const LAYER_WORLD := 1
const LAYER_ENEMIES := 4
const LAYER_PLAYER_HITBOX := 8
const LAYER_ENEMY_HITBOX := 16
const LAYER_ENEMY_HURTBOX := 64
const LAYER_PROPS := 128
const LAYER_PIT := 256                   # AreaBuilder.LAYER_PIT
const KNOCK_TIME := 0.15                 # stun while being pushed back by a hit
const IFRAMES := 0.3                     # one slash can only hit once
const HIT_STOP := 0.05                   # freeze for both sides when a hit lands
const KILL_SHAKE := Vector2(1.0, 0.12)   # (pixels, seconds) of camera shake on a kill
const STUN_ELEMENT := "stun"             # HitBox.element of hits that only stun (boomerang)
const HOOK_ELEMENT := "hook"             # the grapple: stuns like the boomerang unless _hooked() takes it
const ICE_ELEMENT := "ice"               # the ice rod: freezes the enemy in a block of ice unless _iced() takes it
const ICE_TIME := 3.0                    # seconds a frozen enemy stays frozen
const ICE_TINT := Color(0.55, 0.8, 1.0)  # how a frozen enemy looks (sprite self_modulate)
const STUN_TIME := 2.0                   # seconds a stunned enemy stays frozen
const FEET_BOX := Vector2(10, 6)

# Set by subclasses in _init().
var pack := ""
var max_hp := 2
var contact_damage := 2
var body_size := Vector2(12, 12)         # hurt/contact box size, centred on body_center
var body_center := Vector2(0, -7)
var directional := false                 # pack has <anim>_down/up/side strips

var health: HealthComponent
var sprite: AnimatedSprite2D
var hurt_box: HurtBox
var contact: HitBox
var facing := Vector2i.DOWN
var player: Node2D                       # set by the field so the AI can see Joe
var stun_immune := false                 # bosses shrug off the boomerang

var _knock_left := 0.0
var _iframes_left := 0.0
var _frozen_left := 0.0
var _dead := false


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = LAYER_ENEMIES
	collision_mask = LAYER_WORLD | LAYER_PROPS | LAYER_PIT     # pits are walls to enemies
	var feet := CollisionShape2D.new()
	var fr := RectangleShape2D.new()
	fr.size = FEET_BOX
	feet.shape = fr
	feet.position = Vector2(0, -FEET_BOX.y / 2.0)
	add_child(feet)
	var loaded := SpriteStrips.load_pack(SPRITE_DIR, pack)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = loaded["frames"]
	var info: Dictionary = loaded["info"]
	sprite.offset = Vector2(0, float(info["frame_size"][1]) / 2.0 - float(info["feet"][1]))
	HitFlash.attach(sprite)
	add_child(sprite)
	hurt_box = HurtBox.new()
	hurt_box.collision_layer = LAYER_ENEMY_HURTBOX
	hurt_box.collision_mask = LAYER_PLAYER_HITBOX
	hurt_box.add_child(_box_shape("Shape"))
	add_child(hurt_box)
	hurt_box.hurt.connect(_on_hurt)
	contact = HitBox.new()
	contact.collision_layer = LAYER_ENEMY_HITBOX
	contact.collision_mask = 0
	contact.damage = contact_damage
	contact.add_child(_box_shape("Shape"))
	add_child(contact)
	contact.set_active(true)
	health = HealthComponent.new()
	health.max_health = max_hp
	add_child(health)
	health.current_health = max_hp
	_play(_anim_base())


func _box_shape(n: String) -> CollisionShape2D:
	var s := CollisionShape2D.new()
	s.name = n
	var r := RectangleShape2D.new()
	r.size = body_size
	s.shape = r
	s.position = body_center
	return s


func _physics_process(delta: float) -> void:
	if _dead:
		return
	if _frozen_left > 0.0:
		_frozen_left -= delta
		sprite.speed_scale = 0.0
		if _frozen_left <= 0.0:
			sprite.self_modulate = Color.WHITE        # thawed (ice) / woke up (stun)
		return
	sprite.speed_scale = 1.0
	_iframes_left = maxf(0.0, _iframes_left - delta)
	if _knock_left > 0.0:
		_knock_left -= delta
		move_and_slide()
		if _knock_left <= 0.0:
			velocity = Vector2.ZERO
		return
	_think(delta)


# --- for subclasses ----------------------------------------------------------------

func _think(_delta: float) -> void:
	pass


func _anim_base() -> String:
	return "walk"


func _move(v: Vector2) -> void:
	velocity = v
	move_and_slide()


# Face along the dominant axis of `dir` (enemies use cardinal facings).
func _face(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	if absf(dir.x) > absf(dir.y):
		facing = Vector2i(signi(int(signf(dir.x))), 0)
	else:
		facing = Vector2i(0, signi(int(signf(dir.y))))


func _play(base: String) -> void:
	var anim := base
	if directional:
		anim = "%s_%s" % [base, "down" if facing.y > 0 else ("up" if facing.y < 0 else "side")]
		sprite.flip_h = facing.x < 0
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)


func _to_player() -> Vector2:
	if player == null or not is_instance_valid(player):
		return Vector2.INF
	return player.global_position - global_position


# --- damage ------------------------------------------------------------------------

func freeze(seconds: float) -> void:
	_frozen_left = maxf(_frozen_left, seconds)


func is_dead() -> bool:
	return _dead


func _on_hurt(damage: int, source_position: Vector2, knockback: Vector2) -> void:
	if _dead or _iframes_left > 0.0:
		return
	# Armour and elements: a resisted hit only clanks (bosses that need a trick or a particular weapon).
	if hurt_box.last_hit != null and _resists(hurt_box.last_hit):
		_iframes_left = IFRAMES
		Audio.sfx("clank")
		Juice.play_fx("hit_spark", global_position + body_center, get_parent())
		return
	# A "stun" hit (the boomerang) freezes the enemy in place without hurting it, like ALttP.
	var element := hurt_box.last_hit.element if hurt_box.last_hit != null else ""
	if element == HOOK_ELEMENT and _hooked():
		_iframes_left = IFRAMES
		return
	if element == ICE_ELEMENT:
		_iframes_left = IFRAMES
		if not _iced():
			freeze(ICE_TIME)
			sprite.self_modulate = ICE_TINT
			Audio.sfx("freeze")
		return
	if element == STUN_ELEMENT or element == HOOK_ELEMENT:
		if stun_immune:
			return
		_iframes_left = IFRAMES
		freeze(STUN_TIME)
		HitFlash.flash(sprite)
		Audio.sfx("shield_block", 1.4)
		return
	_iframes_left = IFRAMES
	health.take_damage(damage)
	HitFlash.flash(sprite)
	Audio.sfx("enemy_hit")
	var center := global_position + body_center
	Juice.play_fx("hit_spark", center.lerp(source_position, 0.5), get_parent())
	var attacker: Node = hurt_box.last_hit.get_parent() if hurt_box.last_hit != null else null
	Juice.hit_stop([self, attacker], HIT_STOP)
	var away := center - source_position
	velocity = (away.normalized() if away.length() > 0.01 else Vector2.DOWN) * maxf(knockback.x, 1.0)
	_knock_left = KNOCK_TIME
	if not health.is_alive():
		_die()


# Subclasses return true when they handle the ice rod's bolt themselves (the Magma Wyrm is held above the lava).
func _iced() -> bool:
	return false


# Subclasses return true when they handle the grapple's bite themselves (the Gloom Moth is dragged down).
func _hooked() -> bool:
	return false


# Subclasses return true for hits that do nothing to them (checked before stun and damage).
func _resists(_hit: HitBox) -> bool:
	return false


func _die() -> void:
	_dead = true
	contact.set_active(false)
	hurt_box.set_deferred("monitoring", false)
	Audio.sfx("enemy_die")
	Juice.play_fx("poof", global_position + body_center, get_parent())
	Juice.shake(KILL_SHAKE.x, KILL_SHAKE.y)
	defeated.emit(global_position)
	spawn_drop(get_parent(), global_position + body_center)
	queue_free()


# Roll the drop table and leave the pickup (if any) in `parent` at `at`. Shared with pots.
static func spawn_drop(parent: Node, at: Vector2) -> void:
	var kind: String = GameState.roll_drop()
	if kind == "" or parent == null:
		return
	var p: Area2D = PICKUP_SCRIPT.new()
	p.kind = kind
	p.position = at
	parent.add_child.call_deferred(p)
