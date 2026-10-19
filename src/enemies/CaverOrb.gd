# File: CaverOrb.gd
# Description: Caver's magic orb - drifts at Joe and hurts him, but a sword swing bats it back; a batted orb flies at Caver and is the only thing that wounds his shade.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-19
# Last edit date: 2026-10-19
# Version: 1.0.0
extends Node2D
## Two boxes: a HitBox (EnemyHitBox layer, hurts Joe) and a HurtBox listening to Joe's attacks. Batting it back
## moves the HitBox to the PlayerHitBox layer with element "orb" and aims it at the caster.

const TEX := "res://assets/sprites/items/orb.png"
const TEX_BACK := "res://assets/sprites/items/orb_back.png"
const FRAME := Vector2i(14, 14)
const SPEED := 85.0
const BACK_SPEED := 170.0
const DAMAGE := 2
const LIFETIME := 5.0
const RADIUS := 5.0
const ORB_ELEMENT := "orb"
const LAYER_PLAYER_HITBOX := 8
const LAYER_ENEMY_HITBOX := 16
const LAYER_ENEMY_HURTBOX := 64

var direction := Vector2.DOWN
var caster: Node2D
var batted := false

var hit_box: HitBox
var _hurt: HurtBox
var _sprite: AnimatedSprite2D
var _age := 0.0


func _ready() -> void:
	add_to_group("orb")
	_sprite = AnimatedSprite2D.new()
	_set_frames(TEX)
	add_child(_sprite)
	hit_box = HitBox.new()
	hit_box.collision_layer = LAYER_ENEMY_HITBOX
	hit_box.collision_mask = 0
	hit_box.damage = DAMAGE
	hit_box.add_child(_circle(RADIUS))
	add_child(hit_box)
	hit_box.set_active(true)
	hit_box.landed.connect(func(_hb: HurtBox) -> void: queue_free())
	_hurt = HurtBox.new()
	_hurt.collision_layer = LAYER_ENEMY_HURTBOX
	_hurt.collision_mask = LAYER_PLAYER_HITBOX
	_hurt.add_child(_circle(RADIUS + 3.0))
	add_child(_hurt)
	_hurt.hurt.connect(func(_d: int, _src: Vector2, _kb: Vector2) -> void: bat_back())


func _circle(r: float) -> CollisionShape2D:
	var s := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = r
	s.shape = c
	return s


func _set_frames(path: String) -> void:
	var frames := SpriteStrips.new_frames()
	SpriteStrips.add_strip(frames, "pulse", path, FRAME, 8.0, true)
	_sprite.sprite_frames = frames
	_sprite.play("pulse")


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	if batted and is_instance_valid(caster):
		direction = (caster.global_position + Vector2(0, -20) - global_position).normalized()
	position += direction * (BACK_SPEED if batted else SPEED) * delta


# Joe's sword (or any of his attacks) sends the orb back at Caver.
func bat_back() -> void:
	if batted:
		return
	batted = true
	_age = 0.0
	Audio.sfx("shield_block", 1.3)
	_set_frames(TEX_BACK)
	_hurt.set_deferred("monitoring", false)
	hit_box.set_active(false)
	hit_box.collision_layer = LAYER_PLAYER_HITBOX
	hit_box.element = ORB_ELEMENT
	hit_box.damage = 1
	hit_box.set_active(true)
