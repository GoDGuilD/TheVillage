# File: KeyBlock.gd
# Description: A stone block with a keyhole - solid until Joe uses a small key on it (interact); the World spends the key and remembers the opened block through a GameState flag.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
class_name KeyBlock
extends StaticBody2D
## Talkable: the World sees a KeyBlock and either unlocks it or shows the "locked" text.

const TEX := preload("res://assets/sprites/items/key_block.png")
const LAYER_WORLD := 1
const SIZE := Vector2(16, 16)
const LOCKED_TEXT := "locked"

var flag := ""


func _ready() -> void:
	collision_layer = LAYER_WORLD
	collision_mask = 0
	add_to_group("talkable")
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = SIZE
	shape.shape = r
	add_child(shape)
	var s := Sprite2D.new()
	s.texture = TEX
	add_child(s)


func unlock() -> void:
	Juice.play_fx("poof", global_position, get_parent())
	Audio.sfx("unlock")
	remove_from_group("talkable")
	queue_free()


func talk_point() -> Vector2:
	return global_position


func talk(_from: Vector2) -> String:
	return LOCKED_TEXT


func rest() -> void:
	pass
