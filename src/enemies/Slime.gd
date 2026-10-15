# File: Slime.gd
# Description: Jelly slime: sits and wobbles, then hops - toward Joe when he is near, otherwise in a random direction.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
class_name Slime
extends BaseEnemy

const HOP_SPEED := 70.0
const HOP_TIME := 0.4
const REST_MIN := 0.6
const REST_MAX := 1.4
const NOTICE_RANGE := 80.0

var _rest_left := 0.0
var _hop_left := 0.0
var _hop_dir := Vector2.ZERO


func _init() -> void:
	pack = "slime"
	max_hp = 2
	contact_damage = 2
	body_size = Vector2(12, 9)
	body_center = Vector2(0, -5)


func _ready() -> void:
	super._ready()
	_rest_left = randf_range(REST_MIN, REST_MAX)


func _anim_base() -> String:
	return "idle"


func _think(delta: float) -> void:
	if _hop_left > 0.0:
		_hop_left -= delta
		_move(_hop_dir * HOP_SPEED)
		if _hop_left <= 0.0:
			_rest_left = randf_range(REST_MIN, REST_MAX)
			_play("idle")
		return
	_move(Vector2.ZERO)
	_rest_left -= delta
	if _rest_left > 0.0:
		return
	var to := _to_player()
	if to != Vector2.INF and to.length() <= NOTICE_RANGE:
		_hop_dir = to.normalized()
	else:
		_hop_dir = Vector2.RIGHT.rotated(randf() * TAU)
	_hop_left = HOP_TIME
	sprite.play("hop")
