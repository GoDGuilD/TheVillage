# File: GrandSlime.gd
# Description: The Moss Shrine's boss - a huge slime that hops at Joe, buds off small slimes when struck, and hops faster once it is half gone.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-16
# Last edit date: 2026-10-16
# Version: 1.0.0
class_name GrandSlime
extends BaseEnemy
## ALttP-style first boss: readable (a long crouch before every hop), punishes standing still, and spawns adds so the
## spin attack pays off. The World listens to `defeated` (BaseEnemy) for the reward sequence.

const SLIME_SCRIPT := "res://src/enemies/Slime.gd"
const HOP_SPEED := 95.0
const HOP_TIME := 0.55
const REST_TIME := 1.1
const REST_TIME_ANGRY := 0.55            # once below half health
const MAX_MINIONS := 3
const MINION_OFFSET := 20.0

var is_boss := true
var minions: Array = []

var _rest_left := 0.0
var _hop_left := 0.0
var _hop_dir := Vector2.ZERO


func _init() -> void:
	pack = "grand_slime"
	max_hp = 16
	contact_damage = 2
	body_size = Vector2(30, 20)
	body_center = Vector2(0, -12)
	stun_immune = true


func _ready() -> void:
	super._ready()
	_rest_left = REST_TIME
	health.health_changed.connect(_on_health_changed)


func _anim_base() -> String:
	return "idle"


func angry() -> bool:
	return health.current_health * 2 <= health.max_health


func _think(delta: float) -> void:
	if _hop_left > 0.0:
		_hop_left -= delta
		_move(_hop_dir * HOP_SPEED)
		if _hop_left <= 0.0:
			_rest_left = REST_TIME_ANGRY if angry() else REST_TIME
			Audio.sfx("land")
			sprite.play("idle")
		return
	_move(Vector2.ZERO)
	_rest_left -= delta
	if _rest_left > 0.0:
		return
	var to := _to_player()
	_hop_dir = to.normalized() if to != Vector2.INF and to.length() > 1.0 else Vector2.DOWN
	_hop_left = HOP_TIME
	sprite.play("hop")
	Audio.sfx("ledge_hop", 0.6)


# Struck but alive: bud off a small slime (up to MAX_MINIONS alive at once).
func _on_health_changed(current: int, _maximum: int) -> void:
	if current <= 0:
		return
	minions = minions.filter(func(m: Variant) -> bool: return is_instance_valid(m))
	if minions.size() >= MAX_MINIONS or get_parent() == null:
		return
	var m: Node2D = load(SLIME_SCRIPT).new()
	m.position = position + Vector2.RIGHT.rotated(randf() * TAU) * MINION_OFFSET
	m.player = player
	get_parent().add_child.call_deferred(m)
	minions.append(m)
