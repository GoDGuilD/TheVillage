# File: CaverShade.gd
# Description: Caver's shade in the keep's throne room (end of Act 1) - fades between four spots, throws a magic orb at Joe from each, and is wounded only by an orb Joe bats back; three wounds end the act.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-19
# Last edit date: 2026-10-19
# Version: 1.0.0
class_name CaverShade
extends BaseEnemy
## ALttP's Agahnim pattern. Not the real Caver: his mortal form is the final boss (Phase 13).

const ORB_SCRIPT := preload("res://src/enemies/CaverOrb.gd")
const SPOTS := [Vector2(-96, -24), Vector2(96, -24), Vector2(-64, 24), Vector2(64, 24)]
const FADE := 0.4
const SHOW := 0.7                        # s visible before the throw
const AFTER := 1.4                       # s visible after the throw
const ORB_ELEMENT := "orb"

var is_boss := true
var throws := 0
var phase := "show"                      # show | after | fade_out | fade_in

var _home := Vector2.ZERO
var _spot := 0
var _timer := SHOW


func _init() -> void:
	pack = "caver"
	max_hp = 3
	contact_damage = 2
	body_size = Vector2(16, 32)
	body_center = Vector2(0, -20)
	stun_immune = true


func _ready() -> void:
	super._ready()
	_home = position
	collision_mask = 0                    # it floats and fades; nothing blocks it


func _anim_base() -> String:
	return "float"


func _resists(hit: HitBox) -> bool:
	return hit.element != ORB_ELEMENT


func _think(delta: float) -> void:
	_move(Vector2.ZERO)
	_timer -= delta
	match phase:
		"show":
			if _timer <= 0.0:
				throw_orb()
				phase = "after"
				_timer = AFTER
		"after":
			if _timer <= 0.0:
				phase = "fade_out"
				_timer = FADE
		"fade_out":
			sprite.modulate.a = clampf(_timer / FADE, 0.0, 1.0)
			if _timer <= 0.0:
				_spot = (_spot + 1 + randi() % (SPOTS.size() - 1)) % SPOTS.size()
				position = _home + SPOTS[_spot]
				phase = "fade_in"
				_timer = FADE
		"fade_in":
			sprite.modulate.a = 1.0 - clampf(_timer / FADE, 0.0, 1.0)
			if _timer <= 0.0:
				sprite.modulate.a = 1.0
				sprite.play("float")
				phase = "show"
				_timer = SHOW


func throw_orb() -> void:
	throws += 1
	sprite.play("cast")
	Audio.sfx("orb")
	var orb: Node2D = ORB_SCRIPT.new()
	var to := _to_player()
	orb.direction = to.normalized() if to != Vector2.INF and to.length() > 0.1 else Vector2.DOWN
	orb.caster = self
	orb.position = position + body_center
	get_parent().add_child(orb)
