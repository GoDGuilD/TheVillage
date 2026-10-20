# File: Peg.gd
# Description: A wooden peg - a solid stake the Hammer pounds flat into the ground (it stands up again when the area is rebuilt, as in ALttP).
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-23
# Last edit date: 2026-10-23
# Version: 1.0.0
class_name Peg
extends StaticBody2D
## Group "peg". `pound()` flattens it. A pounded peg moves its node to the top of its cell so the y-sorted actors
## walking over it are drawn on top (floor props may not use a negative z_index).

const TEX_UP := preload("res://assets/sprites/dungeon/peg.png")
const TEX_DOWN := preload("res://assets/sprites/dungeon/peg_down.png")
const SIZE := Vector2(12, 12)
const FLAT_LIFT := 9.0                   # px the node moves up once flat (the sprite stays where it was)
const LAYER_WORLD := 1

var is_down := false

var _sprite: Sprite2D
var _shape: CollisionShape2D


func _ready() -> void:
	add_to_group("peg")
	collision_layer = LAYER_WORLD
	collision_mask = 0
	_shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = SIZE
	_shape.shape = r
	add_child(_shape)
	_sprite = Sprite2D.new()
	_sprite.texture = TEX_UP
	add_child(_sprite)


func pound() -> bool:
	if is_down:
		return false
	is_down = true
	_shape.set_deferred("disabled", true)
	_sprite.texture = TEX_DOWN
	position.y -= FLAT_LIFT
	_sprite.position.y += FLAT_LIFT
	Juice.play_fx("poof", global_position + Vector2(0, FLAT_LIFT), get_parent())
	return true
