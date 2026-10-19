# File: Cinder.gd
# Description: The cinder - an Ignis slime of glowing coal that hops at Joe and leaves a short-lived flame wherever it lands.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-22
# Last edit date: 2026-10-22
# Version: 1.0.0
class_name Cinder
extends Slime

const FLAME_SCRIPT := preload("res://src/world/GroundFlame.gd")

var flames_left := 0                     # flames dropped so far (tests)


func _init() -> void:
	pack = "cinder"
	max_hp = 3
	contact_damage = 2


func _think(delta: float) -> void:
	var was_hopping := _hop_left > 0.0
	super._think(delta)
	if was_hopping and _hop_left <= 0.0:
		_drop_flame()


func _drop_flame() -> void:
	var f: Node2D = FLAME_SCRIPT.new()
	f.position = position
	get_parent().add_child(f)
	flames_left += 1
