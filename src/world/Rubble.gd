# File: Rubble.gd
# Description: A pile of loose rocks - solid until Joe dashes into it with the boots, then it scatters for good (remembered through a GameState flag).
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-19
# Last edit date: 2026-10-19
# Version: 1.0.0
class_name Rubble
extends StaticBody2D
## Dash contract: `dash_break()` (the Player calls it on whatever his dash runs into).

signal broken(rubble: Node2D)

const TEX := preload("res://assets/sprites/items/rubble.png")
const SIZE := Vector2(16, 16)
const LAYER_WORLD := 1

var flag := ""


func _ready() -> void:
	collision_layer = LAYER_WORLD
	collision_mask = 0
	add_to_group("dashable")
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = SIZE
	shape.shape = r
	add_child(shape)
	var s := Sprite2D.new()
	s.texture = TEX
	add_child(s)


func dash_break() -> void:
	if is_queued_for_deletion():
		return
	Audio.sfx("shatter", 0.8)
	Juice.play_fx("poof", global_position, get_parent())
	broken.emit(self)
	queue_free()
