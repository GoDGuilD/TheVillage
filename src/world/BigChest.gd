# File: BigChest.gd
# Description: A dungeon's big chest - two tiles wide, opened from below only with that dungeon's big key; holds the dungeon's treasure.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-16
# Last edit date: 2026-10-16
# Version: 1.0.0
class_name BigChest
extends Chest
## Same contract as Chest (talkable, opened flag); the World checks the big key before opening it. The node sits at
## the centre of its two cells.

const BIG_TEX := "res://assets/sprites/dungeon/big_chest.png"
const BIG_FRAME := Vector2i(32, 24)
const BIG_SIZE := Vector2(30, 14)
const BIG_OFFSET := Vector2(0, -4)       # 24-px art standing on a 16-px cell


func _init() -> void:
	tex_path = BIG_TEX
	frame_size = BIG_FRAME
	body_size = BIG_SIZE
	sprite_offset = BIG_OFFSET
	needs_big_key = true
