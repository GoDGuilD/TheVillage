# File: Arrow.gd
# Description: An arrow shot from Joe's bow - flies straight along his facing, hits the first enemy for 4 damage, or sticks in a wall for a moment and vanishes.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
extends CharacterBody2D

const TEX := preload("res://assets/sprites/items/arrow.png")
const SPEED := 300.0
const DAMAGE := 4                        # two sword slashes, as in ALttP
const KNOCKBACK := 140.0
const HEIGHT := 8.0
const MAX_DISTANCE := 400.0              # gone once well off-screen
const STUCK_TIME := 0.3                  # stays in the wall this long
const LAYER_WORLD := 1
const LAYER_PROPS := 128
const LAYER_PLAYER_HITBOX := 8

var direction := Vector2.RIGHT
var stuck := false
var hit_box: HitBox

var _gone := 0.0
var _stuck_left := 0.0


func _ready() -> void:
	add_to_group("arrow")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 0
	collision_mask = LAYER_WORLD | LAYER_PROPS
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 2.0
	shape.shape = c
	add_child(shape)
	var sprite := Sprite2D.new()
	sprite.texture = TEX
	sprite.rotation = direction.angle()
	sprite.position = Vector2(0, -HEIGHT)
	add_child(sprite)
	hit_box = HitBox.new()
	hit_box.collision_layer = LAYER_PLAYER_HITBOX
	hit_box.collision_mask = 0
	hit_box.damage = DAMAGE
	hit_box.knockback = Vector2(KNOCKBACK, 0)
	var hs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = Vector2(8, 8)
	hs.shape = hr
	hs.position = Vector2(0, -HEIGHT)
	hit_box.add_child(hs)
	add_child(hit_box)
	hit_box.set_active(true)
	hit_box.landed.connect(func(_hb: HurtBox) -> void: queue_free())


func _physics_process(delta: float) -> void:
	if stuck:
		_stuck_left -= delta
		if _stuck_left <= 0.0:
			queue_free()
		return
	var step := direction * SPEED * delta
	var hit := move_and_collide(step)
	_gone += step.length()
	if hit != null:
		stuck = true
		_stuck_left = STUCK_TIME
		hit_box.set_active(false)
		Audio.sfx("arrow_hit")
	elif _gone >= MAX_DISTANCE:
		queue_free()
