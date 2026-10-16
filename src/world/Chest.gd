# File: Chest.gd
# Description: A treasure chest - solid, opened from below with the interact button (ALttP), holds one kind of item; can start concealed until every torch of its area is lit.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-16
# Version: 1.1.0
class_name Chest
extends StaticBody2D
## Talkable (group "talkable"): the World sees a Chest and runs the item-get sequence instead of a conversation.
## Opened chests are remembered through a GameState flag (`flag`), set by the World.

const TEX := "res://assets/sprites/items/chest.png"
const FRAME := Vector2i(16, 16)
const LAYER_WORLD := 1
const SIZE := Vector2(14, 12)

var kind := ""                           # what is inside (an ItemDB kind)
var amount := 1
var flag := ""                           # GameState flag set once opened
var opened := false
var concealed := false
var reveal_by := ""                      # "" / "torches" / "switch": what makes a concealed chest appear
var reveal_flag := ""                    # the switch flag for reveal == "switch"
var needs_big_key := false               # big chests (BigChest)
var tex_path := TEX                      # sprite and body size (BigChest overrides them in _init)
var frame_size := FRAME
var body_size := SIZE
var sprite_offset := Vector2.ZERO

var _sprite: AnimatedSprite2D
var _shape: CollisionShape2D


func setup(content: String, count: int, chest_flag: String, is_open: bool, starts_hidden: bool) -> void:
	kind = content
	amount = count
	flag = chest_flag
	opened = is_open
	concealed = starts_hidden and not is_open


func _ready() -> void:
	collision_layer = LAYER_WORLD
	collision_mask = 0
	add_to_group("talkable")
	add_to_group("chest")
	_shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = body_size
	_shape.shape = r
	add_child(_shape)
	var frames := SpriteStrips.new_frames()
	SpriteStrips.add_strip(frames, "chest", tex_path, frame_size, 1.0, false)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.animation = "chest"
	_sprite.offset = sprite_offset
	add_child(_sprite)
	_refresh()


func _refresh() -> void:
	_sprite.frame = 1 if opened else 0
	visible = not concealed
	_shape.set_deferred("disabled", concealed)


# Appear (the torches of the area were all lit).
func reveal() -> void:
	if not concealed:
		return
	concealed = false
	_refresh()


func open() -> void:
	opened = true
	_refresh()


func can_open() -> bool:
	return not opened and not concealed


func talk_point() -> Vector2:
	return global_position


func talk(_from: Vector2) -> String:
	return ""


func rest() -> void:
	pass
