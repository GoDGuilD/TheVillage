# File: HookPost.gd
# Description: A hook post - a dark stake with an iron ring; solid, and the grapple latches onto it to pull Joe across chasms and water.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-21
# Last edit date: 2026-10-21
# Version: 1.0.0
class_name HookPost
extends StaticBody2D
## Hookable contract (group "hookable"): hook_point() -> Vector2, where the grapple's claw bites.

const TEX := preload("res://assets/sprites/dungeon/hook_post.png")
const SIZE := Vector2(12, 12)
const LAYER_WORLD := 1


func _ready() -> void:
	collision_layer = LAYER_WORLD
	collision_mask = 0
	add_to_group("hookable")
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = SIZE
	shape.shape = r
	add_child(shape)
	var s := Sprite2D.new()
	s.texture = TEX
	add_child(s)


func hook_point() -> Vector2:
	return global_position
