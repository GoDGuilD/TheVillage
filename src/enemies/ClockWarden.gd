# File: ClockWarden.gd
# Description: The Clock Warden, master of the Tempus Clocktower - an armoured knight with a clock for a heart that throws gears on every tick and stops Joe in time on every third; the Hammer cracks its armour for the sword.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-23
# Last edit date: 2026-10-20
# Version: 1.0.1
class_name ClockWarden
extends BaseEnemy
## States: "walk" (plods toward Joe; every TICK_TIME s throws GEARS gears - cardinal and diagonal ticks
## alternate - and every STOP_EVERY-th tick stops time: Joe is frozen STOP_TIME s) -> a hammer hit -> "cracked"
## (CRACK_TIME s kneeling: no contact, every hit lands; after CRACK_HITS hits or the time it stands up again).
## Below half health it ticks faster.

const SHOT_SCRIPT := preload("res://src/enemies/EnemyShot.gd")
const GEAR_TEX := preload("res://assets/sprites/items/gear_shot.png")
const WALK_SPEED := 24.0
const TICK_TIME := 1.6
const TICK_TIME_ANGRY := 1.1
const GEARS := 4
const STOP_EVERY := 3
const STOP_TIME := 0.7
const CRACK_TIME := 3.0
const CRACK_HITS := 3

var is_boss := true
var state := "walk"                      # walk | cracked
var ticks := 0
var time_stops := 0
var cracks := 0
var shots_fired := 0

var _tick_left := TICK_TIME
var _timer := 0.0
var _hits_here := 0


func _init() -> void:
	pack = "clock_warden"
	max_hp = 12
	contact_damage = 3
	body_size = Vector2(22, 28)
	body_center = Vector2(0, -18)
	stun_immune = true


func _anim_base() -> String:
	return "walk"


func is_cracked() -> bool:
	return state == "cracked"


func _resists(_hit: HitBox) -> bool:
	return not is_cracked()


func _on_hurt(damage: int, source_position: Vector2, _knockback: Vector2) -> void:
	var hit := hurt_box.last_hit
	if not is_cracked() and hit != null and hit.element == "hammer" and not is_dead():
		_iframes_left = IFRAMES
		state = "cracked"
		cracks += 1
		_timer = CRACK_TIME
		_hits_here = 0
		contact.set_active(false)
		_play("cracked")
		Audio.sfx("clank")
		Juice.shake(2.0, 0.2)
		return
	var before := health.current_health
	super._on_hurt(damage, source_position, Vector2.ZERO)
	if is_cracked() and health.current_health < before:
		_hits_here += 1
		if _hits_here >= CRACK_HITS and health.is_alive():
			_stand()


func _stand() -> void:
	state = "walk"
	_tick_left = TICK_TIME
	contact.set_active(true)
	_play("walk")


func _think(delta: float) -> void:
	if is_cracked():
		_move(Vector2.ZERO)
		_timer -= delta
		if _timer <= 0.0:
			_stand()
		return
	var to := _to_player()
	_move(to.normalized() * WALK_SPEED if to != Vector2.INF and to.length() > 4.0 else Vector2.ZERO)
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	var angry := health.current_health * 2 <= health.max_health
	_tick_left = TICK_TIME_ANGRY if angry else TICK_TIME
	ticks += 1
	Audio.sfx("tick")
	_throw_gears(ticks % 2 == 0)
	if ticks % STOP_EVERY == 0 and player != null and is_instance_valid(player):
		time_stops += 1
		Audio.sfx("time_stop")
		player.call("freeze", STOP_TIME)
		Juice.shake(1.0, STOP_TIME)


func _throw_gears(diagonal: bool) -> void:
	for i in GEARS:
		var shot: CharacterBody2D = SHOT_SCRIPT.new()
		shot.texture = GEAR_TEX
		shot.direction = Vector2.RIGHT.rotated(i * TAU / GEARS + (PI / 4.0 if diagonal else 0.0))
		shot.position = position + Vector2(0, 2)
		get_parent().add_child(shot)
		shots_fired += 1
