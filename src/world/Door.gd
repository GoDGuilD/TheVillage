# File: Door.gd
# Description: A dungeon door filling a 2x2 doorway - locked (small key), big (big key), shutter (opens when a room flag is set) or boss (shuts behind Joe until the boss falls); solid while closed.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-16
# Last edit date: 2026-10-16
# Version: 1.0.0
class_name Door
extends StaticBody2D
## A door shared by two rooms exists in both (same `door_id`), so it blocks from either side; the World decides its
## state from GameState flags when the room is built. Locked and big doors are talkables (the World spends the key).

const TEX_DIR := "res://assets/sprites/dungeon/"
const SIZE := Vector2(32, 32)
const LAYER_WORLD := 1
const INWARD := {"n": Vector2.DOWN, "s": Vector2.UP, "w": Vector2.RIGHT, "e": Vector2.LEFT}

var door_id := ""
var type := "locked"                     # locked | big | shutter | boss
var dir := "n"
var when := ""                           # shutter/boss: the flag that opens it
var is_open := false

var _sprite: Sprite2D
var _shape: CollisionShape2D


func setup(id: String, door_type: String, side: String, open_flag: String, starts_open: bool) -> void:
	door_id = id
	type = door_type
	dir = side
	when = open_flag
	is_open = starts_open


func _ready() -> void:
	collision_layer = LAYER_WORLD
	collision_mask = 0
	add_to_group("door")
	if type == "locked" or type == "big":
		add_to_group("talkable")
	_shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = SIZE
	_shape.shape = r
	add_child(_shape)
	_sprite = Sprite2D.new()
	var art := "shutter" if type == "boss" else type
	_sprite.texture = load(TEX_DIR + "door_%s_%s.png" % [art, dir])
	add_child(_sprite)
	_refresh()


func _refresh() -> void:
	_sprite.visible = not is_open
	_shape.set_deferred("disabled", is_open)


# The flag remembering an opened locked / big door.
func flag() -> String:
	return "door:" + door_id


func open_door(with_sound: bool = true) -> void:
	if is_open:
		return
	is_open = true
	if with_sound:
		Audio.sfx("unlock" if type == "locked" or type == "big" else "shutter")
	remove_from_group("talkable")
	_refresh()


func close_door() -> void:
	if not is_open:
		return
	is_open = false
	Audio.sfx("shutter")
	_refresh()


# The middle of the door's room-facing edge (Joe's one-tile probe reaches it from the doorway).
func talk_point() -> Vector2:
	return global_position + INWARD[dir] * (SIZE.x / 4.0)


func talk(_from: Vector2) -> String:
	return "big_door" if type == "big" else "locked_door"


func rest() -> void:
	pass
