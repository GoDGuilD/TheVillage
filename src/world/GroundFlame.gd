# File: GroundFlame.gd
# Description: A small fire left on the ground where a cinder lands - burns Joe if he walks into it, then dies out.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-22
# Last edit date: 2026-10-22
# Version: 1.0.0
extends Node2D

const TEX := "res://assets/sprites/items/ground_flame.png"
const FRAME := Vector2i(16, 16)
const FPS := 10.0
const LIFETIME := 1.4
const DAMAGE := 2
const RADIUS := 5.0
const LAYER_ENEMY_HITBOX := 16

var hit_box: HitBox
var _age := 0.0


func _ready() -> void:
	add_to_group("ground_flame")
	var frames := SpriteStrips.new_frames()
	SpriteStrips.add_strip(frames, "burn", TEX, FRAME, FPS, true)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.position = Vector2(0, -FRAME.y / 2.0 + 1.0)
	sprite.play("burn")
	add_child(sprite)
	hit_box = HitBox.new()
	hit_box.collision_layer = LAYER_ENEMY_HITBOX
	hit_box.collision_mask = 0
	hit_box.damage = DAMAGE
	var s := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = RADIUS
	s.shape = c
	s.position = Vector2(0, -4)
	hit_box.add_child(s)
	add_child(hit_box)
	hit_box.set_active(true)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
