# File: Lurker.gd
# Description: The lurker - an Umbra shadow with two pale eyes that creeps toward Joe only while his back is turned, and freezes the moment he looks at it.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-21
# Last edit date: 2026-10-21
# Version: 1.0.0
class_name Lurker
extends BaseEnemy
## "Looked at" = Joe faces it within WATCH_DOT (his facing against the direction to the lurker) and it is within
## SIGHT px. Frozen lurkers still hurt on touch and can be struck; they only stop moving.

const CREEP_SPEED := 38.0
const WATCH_DOT := 0.5
const SIGHT := 240.0

var watched := false


func _init() -> void:
	pack = "lurker"
	max_hp = 4
	contact_damage = 2
	body_size = Vector2(14, 14)
	body_center = Vector2(0, -9)


func _anim_base() -> String:
	return "creep"


# True when Joe is looking at this lurker.
func is_watched() -> bool:
	var to := _to_player()
	if to == Vector2.INF or to.length() > SIGHT or to.length() < 0.01:
		return false
	var joe_facing: Vector2 = Vector2(player.get("facing"))
	return joe_facing.dot(-to.normalized()) >= WATCH_DOT


func _think(_delta: float) -> void:
	watched = is_watched()
	if watched:
		_play("frozen")
		_move(Vector2.ZERO)
		return
	var to := _to_player()
	if to == Vector2.INF:
		_move(Vector2.ZERO)
		return
	_play("creep")
	_face(to)
	_move(to.normalized() * CREEP_SPEED)
