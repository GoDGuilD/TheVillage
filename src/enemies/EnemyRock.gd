# File: EnemyRock.gd
# Description: The spitter's rock: flies straight, hurts Joe unless his shield faces it (then it bounces off harmlessly), breaks on walls.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
extends CharacterBody2D

const TEX := preload("res://assets/sprites/enemies/rock.png")
const FRAME := Vector2i(10, 10)
const SPEED := 120.0
const DAMAGE := 2
const LIFETIME := 2.5
const RADIUS := 3.0
const DEFLECT_SPEED := 70.0              # a blocked rock bounces back slowly, then fades
const DEFLECT_TIME := 0.3
const LAYER_WORLD := 1
const LAYER_PROPS := 128
const LAYER_ENEMY_HITBOX := 16

var direction := Vector2.DOWN
var deflected := false
var hit_box: HitBox
var _age := 0.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 0
	collision_mask = LAYER_WORLD | LAYER_PROPS
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = RADIUS
	shape.shape = c
	add_child(shape)
	var spr := AnimatedSprite2D.new()
	var frames := SpriteStrips.new_frames()
	SpriteStrips.add_strip(frames, "spin", TEX.resource_path, FRAME, 12.0, true)
	spr.sprite_frames = frames
	spr.play("spin")
	add_child(spr)
	hit_box = HitBox.new()
	hit_box.collision_layer = LAYER_ENEMY_HITBOX
	hit_box.collision_mask = 0
	hit_box.damage = DAMAGE
	hit_box.blockable = true
	var hs := CollisionShape2D.new()
	var hc := CircleShape2D.new()
	hc.radius = RADIUS + 1.0
	hs.shape = hc
	hit_box.add_child(hs)
	add_child(hit_box)
	hit_box.set_active(true)
	hit_box.landed.connect(_on_landed)


func _physics_process(delta: float) -> void:
	_age += delta
	if deflected:
		modulate.a = clampf(1.0 - _age / DEFLECT_TIME, 0.0, 1.0)
		position += velocity * delta
		if _age >= DEFLECT_TIME:
			queue_free()
		return
	if _age >= LIFETIME:
		queue_free()
		return
	var hit := move_and_collide(direction * SPEED * delta)
	if hit != null:
		Juice.play_fx("hit_spark", global_position, get_parent())
		queue_free()


# Called by Joe when his shield stops the rock.
func deflect() -> void:
	deflected = true
	_age = 0.0
	velocity = -direction * DEFLECT_SPEED
	hit_box.set_active(false)


func _on_landed(_hurt_box: HurtBox) -> void:
	if not deflected:
		queue_free()
