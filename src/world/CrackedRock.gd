# File: CrackedRock.gd
# Description: A cracked rock that only a bomb can break (group "bombable"); breaking it is remembered by the World through a GameState flag.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
class_name CrackedRock
extends StaticBody2D

signal broken(rock: Node2D)

const TEX := preload("res://assets/sprites/items/cracked_rock.png")
const LAYER_WORLD := 1
const SIZE := Vector2(16, 16)

var flag := ""


func _ready() -> void:
	collision_layer = LAYER_WORLD
	collision_mask = 0
	add_to_group("bombable")
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = SIZE
	shape.shape = r
	add_child(shape)
	var s := Sprite2D.new()
	s.texture = TEX
	add_child(s)


# Hit by a bomb's blast.
func blast() -> void:
	if is_queued_for_deletion():
		return
	Juice.play_fx("poof", global_position, get_parent())
	Audio.sfx("shatter", 0.7)
	broken.emit(self)
	queue_free()
