# File: Spitter.gd
# Description: Rock-spitter (octorok style): wanders in short cardinal legs, stops, and spits a rock straight ahead.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
class_name Spitter
extends BaseEnemy

const ROCK_SCRIPT := preload("res://src/enemies/EnemyRock.gd")
const WALK_SPEED := 30.0
const LEG_MIN := 0.8
const LEG_MAX := 1.6
const AIM_TIME := 0.45                   # stands still showing the stretched snout before the rock flies
const RECOVER_TIME := 0.3
const MUZZLE := 9.0                      # rock spawns this far ahead of the body centre

var shots := 0
var _leg_left := 0.0
var _aim_left := 0.0
var _recover_left := 0.0
var _dir := Vector2.DOWN


func _init() -> void:
	pack = "spitter"
	max_hp = 2
	contact_damage = 2
	directional = true
	body_size = Vector2(13, 11)
	body_center = Vector2(0, -7)


func _ready() -> void:
	super._ready()
	_leg_left = randf_range(LEG_MIN, LEG_MAX)


func _think(delta: float) -> void:
	if _aim_left > 0.0:
		_aim_left -= delta
		_move(Vector2.ZERO)
		if _aim_left <= 0.0:
			spit()
			_recover_left = RECOVER_TIME
		return
	if _recover_left > 0.0:
		_recover_left -= delta
		_move(Vector2.ZERO)
		return
	_leg_left -= delta
	if _leg_left <= 0.0:
		_aim_left = AIM_TIME
		_play("spit")
		return
	if get_slide_collision_count() > 0:
		_dir = -_dir
	_face(_dir)
	_play("walk")
	_move(_dir * WALK_SPEED)


# Fire a rock along the facing and pick a new direction for the next leg.
func spit() -> void:
	var rock: Node2D = ROCK_SCRIPT.new()
	rock.direction = Vector2(facing)
	rock.position = position + body_center + Vector2(facing) * MUZZLE
	get_parent().add_child(rock)
	Audio.sfx("spit")
	shots += 1
	_dir = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT][randi() % 4]
	_leg_left = randf_range(LEG_MIN, LEG_MAX)
