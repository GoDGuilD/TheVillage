# File: Thornheart.gd
# Description: The Thornheart, master of the Silva Grove - a giant bud bound in thorny vines on an island in a pool; it spits fans of seeds, and only the fire rod burns its thorns back so the sword can reach its heart.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-20
# Last edit date: 2026-10-20
# Version: 1.0.0
class_name Thornheart
extends BaseEnemy
## Rooted. States: "closed" (every SEED_TIME s spits a fan of SEEDS seeds at Joe, and every RING_EVERY-th volley
## a ring of RING_SEEDS instead; every hit but fire clanks off) -> a fire hit -> "open" (OPEN_TIME s with its petals
## spread: no seeds, no contact, every hit lands; after OPEN_HITS hits or the time it closes up again).
## Below half health it spits faster.

const SHOT_SCRIPT := preload("res://src/enemies/EnemyShot.gd")
const SEED_TEX := preload("res://assets/sprites/items/seed_shot.png")
const FIRE_ELEMENT := "fire"
const SEED_TIME := 1.8
const SEED_TIME_ANGRY := 1.2
const SEEDS := 3
const SPREAD := 0.35                     # radians between two seeds of a fan
const RING_EVERY := 3
const RING_SEEDS := 8
const MOUTH := Vector2(0, -20)           # where the seeds leave the bud (from the feet)
const SHOT_HEIGHT := 8.0                 # EnemyShot.HEIGHT: a shot's sprite floats this high over its ground point
const OPEN_TIME := 4.0
const OPEN_HITS := 3

var is_boss := true
var state := "closed"                    # closed | open
var volleys := 0
var blooms := 0                          # times the fire opened it (tests)
var shots_fired := 0

var _seed_left := SEED_TIME
var _timer := 0.0
var _hits_here := 0


func _init() -> void:
	pack = "thornheart"
	max_hp = 10
	contact_damage = 3
	body_size = Vector2(36, 40)
	body_center = Vector2(0, -26)
	stun_immune = true


func _anim_base() -> String:
	return "closed"


func is_open() -> bool:
	return state == "open"


func _resists(hit: HitBox) -> bool:
	return not is_open() and hit.element != FIRE_ELEMENT


# A fire hit burns the thorns back (no damage); while open every hit lands. Rooted: nothing pushes it.
func _on_hurt(damage: int, source_position: Vector2, _knockback: Vector2) -> void:
	var hit := hurt_box.last_hit
	if not is_open() and hit != null and hit.element == FIRE_ELEMENT and not is_dead():
		_iframes_left = IFRAMES
		state = "open"
		blooms += 1
		_timer = OPEN_TIME
		_hits_here = 0
		contact.set_active(false)
		_play("open")
		Audio.sfx("bloom")
		Juice.play_fx("hit_spark", global_position + body_center, get_parent())
		return
	var before := health.current_health
	super._on_hurt(damage, source_position, Vector2.ZERO)
	if is_open() and health.current_health < before:
		_hits_here += 1
		if _hits_here >= OPEN_HITS and health.is_alive():
			_close()


func _close() -> void:
	state = "closed"
	_seed_left = SEED_TIME
	contact.set_active(true)
	_play("closed")


func _think(delta: float) -> void:
	_move(Vector2.ZERO)
	if is_open():
		_timer -= delta
		if _timer <= 0.0:
			_close()
		return
	_seed_left -= delta
	if _seed_left > 0.0:
		return
	var angry := health.current_health * 2 <= health.max_health
	_seed_left = SEED_TIME_ANGRY if angry else SEED_TIME
	volleys += 1
	Audio.sfx("spit")
	if volleys % RING_EVERY == 0:
		for i in RING_SEEDS:
			_spit(Vector2.RIGHT.rotated(i * TAU / RING_SEEDS))
		return
	var to := _to_player()
	var aim := (to - MOUTH).normalized() if to != Vector2.INF and (to - MOUTH).length() > 0.01 else Vector2.DOWN
	for i in SEEDS:
		_spit(aim.rotated((i - (SEEDS - 1) / 2.0) * SPREAD))


func _spit(dir: Vector2) -> void:
	var shot: CharacterBody2D = SHOT_SCRIPT.new()
	shot.texture = SEED_TEX
	shot.direction = dir
	shot.position = position + MOUTH + Vector2(0, SHOT_HEIGHT)          # the seed's sprite leaves the mouth
	get_parent().add_child(shot)
	shots_fired += 1
