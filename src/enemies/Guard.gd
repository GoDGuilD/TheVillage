# File: Guard.gd
# Description: Caver's cursed village guard: patrols in straight lines, chases Joe along the dominant axis once it sees him (ALttP soldier style).
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
class_name Guard
extends BaseEnemy

const PATROL_SPEED := 30.0
const CHASE_SPEED := 48.0
const SIGHT := 96.0                      # starts chasing inside this distance
const GIVE_UP := 160.0                   # stops chasing beyond this distance
const LEG_MIN := 1.0                     # patrol leg / pause lengths (seconds)
const LEG_MAX := 2.0
const PAUSE := 0.6
const AXIS_DEADZONE := 4.0               # px: below this the chase stops correcting an axis

var chasing := false
var _leg_left := 0.0
var _pause_left := 0.0
var _dir := Vector2.DOWN


func _init() -> void:
	pack = "guard"
	max_hp = 6
	contact_damage = 2
	directional = true
	body_size = Vector2(12, 18)
	body_center = Vector2(0, -10)


func _ready() -> void:
	super._ready()
	_leg_left = randf_range(LEG_MIN, LEG_MAX)


func _think(delta: float) -> void:
	var to := _to_player()
	if to != Vector2.INF:
		if not chasing and to.length() <= SIGHT:
			chasing = true
		elif chasing and to.length() > GIVE_UP:
			chasing = false
	if chasing:
		# Close the larger gap first, like ALttP soldiers (they never cut diagonals).
		var step := Vector2.ZERO
		if absf(to.x) > absf(to.y) and absf(to.x) > AXIS_DEADZONE:
			step = Vector2(signf(to.x), 0)
		elif absf(to.y) > AXIS_DEADZONE:
			step = Vector2(0, signf(to.y))
		_face(step if step != Vector2.ZERO else to)
		_play("walk")
		_move(step * CHASE_SPEED)
		return
	if _pause_left > 0.0:
		_pause_left -= delta
		_move(Vector2.ZERO)
		sprite.pause()
		return
	_leg_left -= delta
	if _leg_left <= 0.0 or get_slide_collision_count() > 0:
		_dir = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT][randi() % 4]
		_leg_left = randf_range(LEG_MIN, LEG_MAX)
		_pause_left = PAUSE
	_face(_dir)
	_play("walk")
	_move(_dir * PATROL_SPEED)
