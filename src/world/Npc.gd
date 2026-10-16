# File: Npc.gd
# Description: A villager - a solid body with a generated idle animation in three facings; turns to face Joe when he talks to them and names the dialogue entry to show.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
class_name Npc
extends StaticBody2D
## Talkable contract (group "talkable"): talk_point() -> Vector2 where Joe's probe must land, and
## talk(from: Vector2) -> String, the dialogue key. `across` puts the talk point one tile in front of the
## villager, so Joe can speak over a shop counter.

const SPRITE_DIR := "res://assets/sprites/npcs/"
const LAYER_WORLD := 1
const BODY_SIZE := Vector2(12, 8)
const TILE := 16.0
const CENTER_UP := 8.0                   # talk point: the middle of the villager's tile, not the feet
const FACINGS := {"down": Vector2i.DOWN, "up": Vector2i.UP, "left": Vector2i.LEFT, "right": Vector2i.RIGHT}

var npc_id := ""
var facing := Vector2i.DOWN
var home_facing := Vector2i.DOWN
var across := false
var sprite: AnimatedSprite2D


# Configure before adding to the tree.
func setup(id: String, facing_name: String, talk_across: bool) -> void:
	npc_id = id
	home_facing = FACINGS.get(facing_name, Vector2i.DOWN)
	facing = home_facing
	across = talk_across


func _ready() -> void:
	collision_layer = LAYER_WORLD
	collision_mask = 0
	add_to_group("talkable")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = BODY_SIZE
	shape.shape = rect
	shape.position = Vector2(0, -BODY_SIZE.y / 2.0)
	add_child(shape)
	var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SPRITE_DIR + "npcs.json"))
	var fs: Array = m["frame"]
	var feet: Array = m["feet"]
	var frames := SpriteStrips.new_frames()
	for view in ["down", "up", "side"]:
		SpriteStrips.add_strip(frames, view, SPRITE_DIR + "%s_idle_%s.png" % [npc_id, view],
				Vector2i(int(fs[0]), int(fs[1])), float(m["fps"]), true)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.offset = Vector2(0, float(fs[1]) / 2.0 - float(feet[1]))
	add_child(sprite)
	face(facing)


func face(dir: Vector2i) -> void:
	facing = dir
	var view := "side" if dir.x != 0 else ("up" if dir == Vector2i.UP else "down")
	sprite.flip_h = dir == Vector2i.LEFT
	if sprite.animation != view:
		sprite.play(view)


func talk_point() -> Vector2:
	var p := global_position - Vector2(0, CENTER_UP)
	return p + Vector2(home_facing) * TILE if across else p


# Turn toward Joe (dominant axis) and return the dialogue key. A villager behind a counter keeps facing it.
func talk(from: Vector2) -> String:
	if not across:
		var d := from - global_position
		if absf(d.x) > absf(d.y):
			face(Vector2i.RIGHT if d.x > 0.0 else Vector2i.LEFT)
		else:
			face(Vector2i.DOWN if d.y > 0.0 else Vector2i.UP)
	return npc_id


# Back to the facing they stand in (after the conversation).
func rest() -> void:
	face(home_facing)
