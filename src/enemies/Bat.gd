# File: Bat.gd
# Description: A cave bat - flits in short erratic legs (drawn toward Joe when he is near), flies over pits and props, dies to one hit.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-19
# Last edit date: 2026-10-19
# Version: 1.0.0
class_name Bat
extends BaseEnemy

const SPEED := 58.0
const LEG_MIN := 0.3
const LEG_MAX := 0.7
const NOTICE := 110.0
const WOBBLE := 1.0                      # radians of randomness around the heading toward Joe
const LAYER_WORLD_ONLY := 1

var _dir := Vector2.RIGHT
var _leg_left := 0.0


func _init() -> void:
	pack = "bat"
	max_hp = 1
	contact_damage = 1
	body_size = Vector2(12, 8)
	body_center = Vector2(0, -10)


func _ready() -> void:
	super._ready()
	collision_mask = LAYER_WORLD_ONLY     # flies: pits and pots do not stop it


func _anim_base() -> String:
	return "fly"


func _think(delta: float) -> void:
	_leg_left -= delta
	if _leg_left <= 0.0 or get_slide_collision_count() > 0:
		_leg_left = randf_range(LEG_MIN, LEG_MAX)
		var to := _to_player()
		if to != Vector2.INF and to.length() <= NOTICE:
			_dir = to.normalized().rotated(randf_range(-WOBBLE, WOBBLE))
		else:
			_dir = Vector2.RIGHT.rotated(randf() * TAU)
	_move(_dir * SPEED)
