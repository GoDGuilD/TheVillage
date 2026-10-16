# File: Torch.gd
# Description: A stone torch post - solid, unlit until the lantern's flame touches its bowl; then it burns (animated) and tells the World, which reveals hidden chests once every torch in the area burns.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
class_name Torch
extends StaticBody2D
## Torches go out again when the area is left (ALttP rooms reset); a chest they revealed stays open once opened.

signal lit_up

const UNLIT := "res://assets/sprites/items/torch_unlit.png"
const LIT := "res://assets/sprites/items/torch_lit.png"
const FRAME := Vector2i(16, 24)
const FPS := 8.0
const LAYER_WORLD := 1
const SIZE := Vector2(12, 12)
const TILE_HALF := 8.0

var lit := false
var _sprite: AnimatedSprite2D


func _ready() -> void:
	collision_layer = LAYER_WORLD
	collision_mask = 0
	add_to_group("torch")
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = SIZE
	shape.shape = r
	add_child(shape)
	var frames := SpriteStrips.new_frames()
	SpriteStrips.add_strip(frames, "unlit", UNLIT, FRAME, 1.0, false)
	SpriteStrips.add_strip(frames, "lit", LIT, FRAME, FPS, true)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.offset = Vector2(0, TILE_HALF - float(FRAME.y) / 2.0)   # stands on its tile, flame above it
	_sprite.play("unlit")
	add_child(_sprite)


# Where the lantern's flame must land (the tile centre).
func flame_point() -> Vector2:
	return global_position


func light() -> void:
	if lit:
		return
	lit = true
	_sprite.play("lit")
	lit_up.emit()
