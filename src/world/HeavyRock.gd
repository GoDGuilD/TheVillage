# File: HeavyRock.gd
# Description: A heavy dark rock - solid, and liftable only once Joe has the power glove (then it is carried and thrown like a pot).
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-16
# Last edit date: 2026-10-16
# Version: 1.0.0
class_name HeavyRock
extends StaticBody2D
## Liftable contract (group "liftable"): can_lift(), lift() -> {kind, texture}. Rocks come back when the area is
## rebuilt, like bushes and pots.

const TEX := preload("res://assets/sprites/dungeon/heavy_rock.png")
const SIZE := Vector2(14, 14)
const LAYER_WORLD := 1


func _ready() -> void:
	collision_layer = LAYER_WORLD
	collision_mask = 0
	add_to_group("liftable")
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = SIZE
	shape.shape = r
	add_child(shape)
	var s := Sprite2D.new()
	s.texture = TEX
	add_child(s)


func can_lift() -> bool:
	return GameState.has_item("glove") and not is_queued_for_deletion()


func lift() -> Dictionary:
	remove_from_group("liftable")
	queue_free()
	return {"kind": "rock", "texture": TEX}
