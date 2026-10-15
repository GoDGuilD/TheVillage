# File: Pot.gd
# Description: Clay pot: a solid prop Joe can lift (interact) and throw; it shatters where it lands and may drop an item.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
class_name Pot
extends StaticBody2D
## Origin = the centre of its tile. Like ALttP pots, the sword does not break it: it has no HurtBox.

const TEX := preload("res://assets/sprites/props/pot.png")
const SOLID_BOX := Vector2(12, 10)
const LAYER_PROPS := 128

var _lifted := false


func _ready() -> void:
	add_to_group("liftable")
	collision_layer = LAYER_PROPS
	collision_mask = 0
	var spr := Sprite2D.new()
	spr.texture = TEX
	add_child(spr)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SOLID_BOX
	shape.shape = rect
	shape.position = Vector2(0, 2)
	add_child(shape)


# Liftable contract: hand over what Joe carries and leave the world.
func lift() -> Dictionary:
	_lifted = true
	queue_free()
	return {"kind": "pot", "texture": TEX}


func can_lift() -> bool:
	return not _lifted
