# File: FrostWraith.gd
# Description: Boss of the Frost Vault - a hooded drift of ice that loops around its room and casts fans of ice shards; only fire (the fire rod) can hurt it.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-19
# Last edit date: 2026-10-19
# Version: 1.0.0
class_name FrostWraith
extends BaseEnemy
## ALttP pattern: the boss needs the dungeon's treasure. Sword, arrows and bombs clank off; fireballs burn.

const SHOT_SCRIPT := preload("res://src/enemies/EnemyShot.gd")
const SHARD_TEX := preload("res://assets/sprites/items/ice_shard.png")
const LOOP_X := 80.0                     # size of its figure-eight around where it started
const LOOP_Y := 32.0
const LOOP_SPEED := 0.7
const FOLLOW := 3.0                      # how fast it slides toward its point on the loop
const CAST_EVERY := 2.6
const CAST_TIME := 0.5
const SHARDS := 3
const SPREAD := 0.35                     # radians between shards
const FIRE_ELEMENT := "fire"
const LAYER_WORLD_ONLY := 1

var is_boss := true
var casts := 0

var _anchor := Vector2.ZERO
var _t := 0.0
var _cast_left := CAST_EVERY
var _casting := 0.0


func _init() -> void:
	pack = "frost_wraith"
	max_hp = 16
	contact_damage = 2
	body_size = Vector2(20, 26)
	body_center = Vector2(0, -22)
	stun_immune = true


func _ready() -> void:
	super._ready()
	_anchor = position
	collision_mask = LAYER_WORLD_ONLY      # floats over pits


func _anim_base() -> String:
	return "float"


func _resists(hit: HitBox) -> bool:
	return hit.element != FIRE_ELEMENT


func _think(delta: float) -> void:
	_t += delta * LOOP_SPEED
	var target := _anchor + Vector2(cos(_t) * LOOP_X, sin(_t * 2.0) * LOOP_Y)
	_move((target - position) * FOLLOW)
	if _casting > 0.0:
		_casting -= delta
		if _casting <= 0.0:
			_play("float")
		return
	_cast_left -= delta
	if _cast_left <= 0.0:
		_cast_left = CAST_EVERY
		cast()


# A fan of ice shards toward Joe.
func cast() -> void:
	casts += 1
	_casting = CAST_TIME
	sprite.play("cast")
	Audio.sfx("ice_shard")
	var to := _to_player()
	var aim := to.normalized() if to != Vector2.INF and to.length() > 0.1 else Vector2.DOWN
	for i in SHARDS:
		var shot: CharacterBody2D = SHOT_SCRIPT.new()
		shot.texture = SHARD_TEX
		shot.direction = aim.rotated((i - (SHARDS - 1) / 2.0) * SPREAD)
		shot.position = position + body_center + Vector2(0, 8)
		get_parent().add_child(shot)
