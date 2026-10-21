# File: CaverLord.gd
# Description: Caver's mortal form, master of his tower and the final boss - fades from spot to spot casting magic orbs (bat one back to knock him down, then strike while he kneels) and volleys of dimension bolts; below half health his cape spreads into bat wings, he casts faster and calls bats; when he falls he sinks through the floor.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-20
# Last edit date: 2026-10-20
# Version: 1.0.0
class_name CaverLord
extends BaseEnemy
## ALttP's Agahnim and Ganon in one: phases "show" (SHOW s visible, then a cast) -> "after" (AFTER s) -> "fade_out"
## -> a new spot -> "fade_in" -> "show". Every VOLLEY_EVERY-th cast is a fan of VOLLEY_BOLTS dimension bolts
## (a ring of RING_BOLTS once angry) that only the shield stops; every other cast is a CaverOrb.
## Only a batted orb touches him while he floats: it wounds him (1) and knocks him down - "dazed" for DAZE_TIME s,
## when every hit lands - then he rises and fades away. Below half health ("angry") he casts faster, fires a
## volley every other cast, and each fade-in calls a bat while fewer than MAX_BATS fly.
## Death: no poof - he kneels and sinks through the floor (SINK_TIME s); the World then plays the final ending.

const ORB_SCRIPT := preload("res://src/enemies/CaverOrb.gd")
const SHOT_SCRIPT := preload("res://src/enemies/EnemyShot.gd")
const BAT_SCRIPT := preload("res://src/enemies/Bat.gd")
const BOLT_TEX := "res://assets/sprites/items/caver_bolt_%d.png"    # 0..3: Umbra, Ignis, Tempus, Silva
const DIMENSIONS := 4
const ORB_ELEMENT := "orb"               # CaverOrb.ORB_ELEMENT
const SPOTS := [Vector2(-112, -16), Vector2(112, -16), Vector2(-80, 40), Vector2(80, 40), Vector2(0, -24),
		Vector2(0, 48)]                  # offsets from the room's start spot
const FADE := 0.4
const SHOW := 0.8                        # s visible before a cast
const SHOW_ANGRY := 0.5
const AFTER := 1.2                       # s visible after a cast
const AFTER_ANGRY := 0.8
const VOLLEY_EVERY := 3                  # every third cast is a volley of bolts...
const VOLLEY_EVERY_ANGRY := 2            # ...every second once angry
const VOLLEY_BOLTS := 5
const VOLLEY_SPREAD := 0.3               # radians between two bolts of a fan
const RING_BOLTS := 10
const CAST_POINT := Vector2(0, -46)      # the orb forms above his raised hands (from the feet)
const SHOT_HEIGHT := 8.0                 # EnemyShot.HEIGHT: a bolt's sprite floats this high over its ground point
const DAZE_TIME := 2.6
const MAX_BATS := 2
const BAT_DROP := Vector2(0, 12)         # a called bat appears just below him
const SINK_TIME := 1.4
const SINK_SHAKE := Vector2(3.0, 1.2)    # (pixels, seconds) of camera shake while he sinks

var is_boss := true
var phase := "show"                      # show | after | fade_out | fade_in | dazed | sinking
var casts := 0
var orbs_thrown := 0
var volleys := 0
var shots_fired := 0
var dazes := 0
var bats_called := 0

var _home := Vector2.ZERO
var _spot := -1
var _timer := SHOW
var _bolts: Array[Texture2D] = []


func _init() -> void:
	pack = "caver_lord"
	max_hp = 12
	contact_damage = 3
	body_size = Vector2(18, 34)
	body_center = Vector2(0, -24)
	stun_immune = true


func _ready() -> void:
	super._ready()
	_home = position
	collision_mask = 0                   # he floats and fades; nothing blocks him
	for i in DIMENSIONS:
		_bolts.append(load(BOLT_TEX % i))


func is_angry() -> bool:
	return health.current_health * 2 <= health.max_health


func is_dazed() -> bool:
	return phase == "dazed"


func _anim_base() -> String:
	return "rage" if health != null and is_angry() else "float"


# Floating, only a batted orb reaches him; knocked down, everything does.
func _resists(hit: HitBox) -> bool:
	return not is_dazed() and hit.element != ORB_ELEMENT


# A batted orb wounds him and knocks him down; hits never push him.
func _on_hurt(damage: int, source_position: Vector2, _knockback: Vector2) -> void:
	var hit := hurt_box.last_hit
	var by_orb := hit != null and hit.element == ORB_ELEMENT and not is_dazed()
	var before := health.current_health
	super._on_hurt(damage, source_position, Vector2.ZERO)
	if by_orb and health.current_health < before and not is_dead():
		_daze()
	elif health.current_health < before and not is_dead() and is_dazed():
		_play("dazed")                   # stay knelt (the hit flash must not restart his float)


func _daze() -> void:
	phase = "dazed"
	dazes += 1
	_timer = DAZE_TIME
	sprite.modulate.a = 1.0
	contact.set_active(false)
	_play("dazed")
	Audio.sfx("daze")


func _think(delta: float) -> void:
	_move(Vector2.ZERO)
	_timer -= delta
	match phase:
		"show":
			if _timer <= 0.0:
				cast()
				phase = "after"
				_timer = AFTER_ANGRY if is_angry() else AFTER
		"after":
			if _timer <= 0.0:
				phase = "fade_out"
				_timer = FADE
		"dazed":
			if _timer <= 0.0:
				contact.set_active(true)
				phase = "fade_out"
				_timer = FADE
		"fade_out":
			sprite.modulate.a = clampf(_timer / FADE, 0.0, 1.0)
			if _timer <= 0.0:
				_spot = (_spot + 1 + randi() % (SPOTS.size() - 1)) % SPOTS.size()
				position = _home + SPOTS[_spot]
				phase = "fade_in"
				_timer = FADE
				_play(_anim_base())
		"fade_in":
			sprite.modulate.a = 1.0 - clampf(_timer / FADE, 0.0, 1.0)
			if _timer <= 0.0:
				sprite.modulate.a = 1.0
				_play(_anim_base())       # wings once angry (also if he was hit to half health while knelt)
				phase = "show"
				_timer = SHOW_ANGRY if is_angry() else SHOW
				if is_angry():
					call_bat()


# One cast: a volley of dimension bolts every VOLLEY_EVERY-th time, else a magic orb.
func cast() -> void:
	casts += 1
	_play("rage_cast" if is_angry() else "cast")
	if casts % (VOLLEY_EVERY_ANGRY if is_angry() else VOLLEY_EVERY) == 0:
		volley()
	else:
		throw_orb()


func throw_orb() -> void:
	orbs_thrown += 1
	Audio.sfx("orb")
	var orb: Node2D = ORB_SCRIPT.new()
	var to := _to_player()
	var from := CAST_POINT
	orb.direction = (to - from).normalized() if to != Vector2.INF and (to - from).length() > 0.1 else Vector2.DOWN
	orb.caster = self
	orb.position = position + from
	get_parent().add_child(orb)


# A fan of bolts at Joe (a full ring once angry), all of one dimension, the next one each volley.
func volley() -> void:
	volleys += 1
	Audio.sfx("fireball")
	var tex: Texture2D = _bolts[(volleys - 1) % DIMENSIONS]
	if is_angry():
		for i in RING_BOLTS:
			_bolt(Vector2.RIGHT.rotated(i * TAU / RING_BOLTS), tex)
		return
	var to := _to_player()
	var aim := (to - CAST_POINT).normalized() if to != Vector2.INF and (to - CAST_POINT).length() > 0.01 else Vector2.DOWN
	for i in VOLLEY_BOLTS:
		_bolt(aim.rotated((i - (VOLLEY_BOLTS - 1) / 2.0) * VOLLEY_SPREAD), tex)


func _bolt(dir: Vector2, tex: Texture2D) -> void:
	var shot: CharacterBody2D = SHOT_SCRIPT.new()
	shot.texture = tex
	shot.direction = dir
	shot.position = position + CAST_POINT + Vector2(0, SHOT_HEIGHT)
	get_parent().add_child(shot)
	shots_fired += 1


# Below half health each fade-in calls a bat (while fewer than MAX_BATS of his fly).
func call_bat() -> void:
	var flying := 0
	for n in get_parent().get_children():
		if n.is_in_group("caver_bat") and not n.is_queued_for_deletion():
			flying += 1
	if flying >= MAX_BATS:
		return
	var bat: Node2D = BAT_SCRIPT.new()
	bat.position = position + BAT_DROP
	bat.player = player
	bat.add_to_group("caver_bat")
	get_parent().add_child(bat)
	bats_called += 1


# He does not burst: he kneels and sinks through the floor (the World starts the ending on `defeated`).
func _die() -> void:
	_dead = true
	phase = "sinking"
	contact.set_active(false)
	hurt_box.set_deferred("monitoring", false)
	sprite.modulate.a = 1.0
	_play("dazed")
	Audio.sfx("sink")
	Juice.shake(SINK_SHAKE.x, SINK_SHAKE.y)
	defeated.emit(global_position)
	var tw := create_tween()
	tw.tween_property(sprite, "scale:y", 0.0, SINK_TIME)       # shrinks toward his feet: into the floor
	tw.parallel().tween_property(sprite, "modulate:a", 0.0, SINK_TIME)
	tw.tween_callback(queue_free)
