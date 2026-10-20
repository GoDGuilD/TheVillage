# File: MagmaWyrm.gd
# Description: The Magma Wyrm, master of the Ignis Forge - rises from the lava pools of its room to spit embers at Joe, and sinks again; only the Ice Rod can hold it above the lava, frozen, for the sword.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-22
# Last edit date: 2026-10-20
# Version: 1.0.1
class_name MagmaWyrm
extends BaseEnemy
## Cycle: "under" (hidden, untouchable) -> "rise" at a lava cell of its room -> "up" (spits two fans of embers; its
## body burns on touch; every hit but ice clanks) -> "sink" -> "under". An ice hit while rising or up -> "frozen"
## (FROZEN_TIME s, sword hits land; after FROZEN_HITS hits or the time it thaws and sinks). Below half health it
## spends less time under and spits wider fans.

const SHOT_SCRIPT := preload("res://src/enemies/EnemyShot.gd")
const EMBER_TEX := preload("res://assets/sprites/items/ember_shot.png")
const UNDER_TIME := 1.3
const UNDER_TIME_ANGRY := 0.8
const RISE_TIME := 0.5
const UP_TIME := 2.6
const SINK_TIME := 0.5
const SPIT_AT := [0.7, 1.7]              # s into "up" when it spits
const SHOTS := 3
const SHOTS_ANGRY := 5
const SPREAD := 0.3
const FROZEN_TIME := 3.5
const FROZEN_HITS := 3
const POOL_REACH := 200.0                # px around its spawn where its lava cells are looked for
const SEED := 4242

var is_boss := true
var state := "under"                     # under | rise | up | sink | frozen
var surfacings := 0
var freezes := 0
var shots_fired := 0
var spots: Array[Vector2] = []           # feet positions it can rise at (lava cells of its room)

var _timer := 0.0
var _spat := 0
var _hits_here := 0
var _home := Vector2.ZERO
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	pack = "magma_wyrm"
	max_hp = 12
	contact_damage = 3
	body_size = Vector2(20, 26)
	body_center = Vector2(0, -26)
	stun_immune = true


func _ready() -> void:
	super._ready()
	_rng.seed = SEED
	_home = position
	_go_under()


func _anim_base() -> String:
	return "up"


func is_frozen() -> bool:
	return state == "frozen"


func is_up() -> bool:
	return state == "rise" or state == "up" or state == "frozen"


func _resists(hit: HitBox) -> bool:
	return not is_frozen() and hit.element != BaseEnemy.ICE_ELEMENT


# Ice holds it above the lava while it is out; under the lava (or sinking) the bolt finds nothing.
func _iced() -> bool:
	if state == "rise" or state == "up":
		state = "frozen"
		freezes += 1
		_timer = FROZEN_TIME
		_hits_here = 0
		contact.set_active(false)
		_play("frozen")
		Audio.sfx("freeze")
	return true


func _on_hurt(damage: int, source_position: Vector2, _knockback: Vector2) -> void:
	var before := health.current_health
	super._on_hurt(damage, source_position, Vector2.ZERO)
	if is_frozen() and health.current_health < before:
		_hits_here += 1
		if _hits_here >= FROZEN_HITS and health.is_alive():
			_sink()


# The lava cells of its room (looked up once the room's tiles are in the tree).
func _find_spots() -> void:
	for node in get_tree().get_nodes_in_group("terrain"):
		var tiles := node as TileMapLayer
		for cell in tiles.get_used_cells():
			var td := tiles.get_cell_tile_data(cell)
			if td == null or not bool(td.get_custom_data("lava")):
				continue
			var feet := tiles.to_global(tiles.map_to_local(cell)) + Vector2(0, 6)
			if feet.distance_to(_home) <= POOL_REACH:
				spots.append(feet)
	if spots.is_empty():
		spots.append(_home)


func _set_out(on: bool) -> void:
	sprite.visible = on
	hurt_box.set_deferred("monitoring", on)
	contact.set_active(on and state == "up")


func _go_under() -> void:
	state = "under"
	var angry := health.current_health * 2 <= health.max_health
	_timer = UNDER_TIME_ANGRY if angry else UNDER_TIME
	_set_out(false)


func _rise() -> void:
	if spots.is_empty():
		_find_spots()
	position = spots[_rng.randi_range(0, spots.size() - 1)]
	state = "rise"
	surfacings += 1
	_timer = RISE_TIME
	_set_out(true)
	_play("rise")
	Audio.sfx("lava_burst")


func _sink() -> void:
	state = "sink"
	_timer = SINK_TIME
	contact.set_active(false)
	_play("sink")


func _think(delta: float) -> void:
	velocity = Vector2.ZERO
	_timer -= delta
	match state:
		"under":
			if _timer <= 0.0:
				_rise()
		"rise":
			if _timer <= 0.0:
				state = "up"
				_timer = UP_TIME
				_spat = 0
				contact.set_active(true)
				_play("up")
		"up":
			if _spat < SPIT_AT.size() and UP_TIME - _timer >= float(SPIT_AT[_spat]):
				_spat += 1
				var angry := health.current_health * 2 <= health.max_health
				_spit(SHOTS_ANGRY if angry else SHOTS)
			if _timer <= 0.0:
				_sink()
		"frozen":
			if _timer <= 0.0:
				_sink()
		"sink":
			if _timer <= 0.0:
				_go_under()


func _spit(count: int) -> void:
	var to := _to_player()
	if to == Vector2.INF:
		return
	var aim := (to - body_center).normalized()
	for i in count:
		var shot: CharacterBody2D = SHOT_SCRIPT.new()
		shot.texture = EMBER_TEX
		shot.direction = aim.rotated((i - (count - 1) / 2.0) * SPREAD)
		shot.position = position + Vector2(0, 2)
		get_parent().add_child(shot)
		shots_fired += 1
	Audio.sfx("spit", 0.7)
