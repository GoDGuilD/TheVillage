# File: GloomMoth.gd
# Description: The Gloom Moth, master of the Umbra sanctum - flies out of the sword's reach scattering dust shots; the grapple drags it down, and only on the ground can it be struck.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-21
# Last edit date: 2026-10-21
# Version: 1.0.0
class_name GloomMoth
extends BaseEnemy
## States: "fly" (drifts on a slow loop around its home, every SHOT_EVERY s throws a fan of dust at Joe; resists
## every hit and does not touch Joe) -> hooked by the grapple -> "grounded" (GROUND_TIME s, sword hits land) ->
## "fly" again (also after GROUND_HITS hits). Faster and with more dust below half health.

const SHOT_SCRIPT := preload("res://src/enemies/EnemyShot.gd")
const DUST_TEX := preload("res://assets/sprites/items/dust_shot.png")
const LOOP_RADIUS := Vector2(88, 34)     # px of its flight loop around home
const LOOP_SPEED := 0.9                  # rad/s
const LOOP_SPEED_ANGRY := 1.4
const SHOT_EVERY := 2.2
const SHOTS := 3
const SHOTS_ANGRY := 5
const SPREAD := 0.32                     # rad between two dust shots
const GROUND_TIME := 3.0
const GROUND_HITS := 3                   # a grounded moth takes off after this many hits
const DIVE_SPEED := 160.0                # px/s while being dragged down toward where the claw bit
const AIR_BODY := Vector2(0, -26)        # where the hurt box sits while flying / on the ground
const GROUND_BODY := Vector2(0, -10)

var is_boss := true
var state := "fly"                       # fly | grounded
var groundings := 0
var shots_fired := 0

var _home := Vector2.ZERO
var _angle := 0.0
var _timer := 0.0
var _shot_left := SHOT_EVERY
var _hits_here := 0


func _init() -> void:
	pack = "gloom_moth"
	max_hp = 12
	contact_damage = 2
	body_size = Vector2(30, 24)
	body_center = AIR_BODY
	stun_immune = true


func _ready() -> void:
	super._ready()
	_home = position
	_set_airborne(true)


func _anim_base() -> String:
	return "fly"


func is_grounded() -> bool:
	return state == "grounded"


# In the air nothing reaches it (the grapple's hook is handled in _hooked).
func _resists(hit: HitBox) -> bool:
	return not is_grounded() and hit.element != BaseEnemy.HOOK_ELEMENT


# The grapple bit: down it comes.
func _hooked() -> bool:
	if not is_grounded():
		_land()
	return true


func _land() -> void:
	state = "grounded"
	groundings += 1
	_timer = GROUND_TIME
	_hits_here = 0
	_set_airborne(false)
	_play("grounded")
	Audio.sfx("bonk")
	Juice.shake(2.0, 0.2)


func _take_off() -> void:
	state = "fly"
	_shot_left = SHOT_EVERY
	_set_airborne(true)
	_play("fly")


func _set_airborne(on: bool) -> void:
	body_center = AIR_BODY if on else GROUND_BODY
	for box in [hurt_box, contact]:
		var shape := box.get_node("Shape") as CollisionShape2D
		shape.position = body_center
	contact.set_active(not on)


# No knockback for a boss this big; a grounded moth takes off again after GROUND_HITS hits.
func _on_hurt(damage: int, source_position: Vector2, _knockback: Vector2) -> void:
	var before := health.current_health
	super._on_hurt(damage, source_position, Vector2.ZERO)
	if is_grounded() and health.current_health < before:
		_hits_here += 1
		if _hits_here >= GROUND_HITS and health.is_alive():
			_take_off()


func _think(delta: float) -> void:
	velocity = Vector2.ZERO
	var angry := health.current_health * 2 <= max_hp
	if is_grounded():
		_timer -= delta
		if _timer <= 0.0:
			_take_off()
		return
	_angle += (LOOP_SPEED_ANGRY if angry else LOOP_SPEED) * delta
	var target := _home + Vector2(cos(_angle) * LOOP_RADIUS.x, sin(_angle * 2.0) * LOOP_RADIUS.y)
	_move((target - position) * 4.0)
	_shot_left -= delta
	if _shot_left <= 0.0:
		_shot_left = SHOT_EVERY
		_throw_dust(SHOTS_ANGRY if angry else SHOTS)


func _throw_dust(count: int) -> void:
	var to := _to_player()
	if to == Vector2.INF:
		return
	var aim := (to - AIR_BODY).normalized()
	for i in count:
		var shot: CharacterBody2D = SHOT_SCRIPT.new()
		shot.texture = DUST_TEX
		shot.direction = aim.rotated((i - (count - 1) / 2.0) * SPREAD)
		shot.position = position + Vector2(0, 2)
		get_parent().add_child(shot)
		shots_fired += 1
	Audio.sfx("spit", 0.8)
