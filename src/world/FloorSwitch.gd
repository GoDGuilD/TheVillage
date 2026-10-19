# File: FloorSwitch.gd
# Description: A floor switch - pressed for good when Joe (or, for a heavy switch, only a push block) stands on it; tells the World, which sets its flag (opening shutters, revealing chests).
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-16
# Last edit date: 2026-10-20
# Version: 1.0.1
class_name FloorSwitch
extends Area2D

signal pressed_down(switch_flag: String)

const TEX := "res://assets/sprites/dungeon/switch.png"
const FRAME := Vector2i(16, 16)
const SIZE := Vector2(10, 10)
const LAYER_WORLD := 1
const LAYER_PLAYER := 2

var flag := ""
var heavy := false                       # only a push block presses it
var pressed := false

var _sprite: AnimatedSprite2D


func setup(switch_flag: String, needs_block: bool, already: bool) -> void:
	flag = switch_flag
	heavy = needs_block
	pressed = already


func _ready() -> void:
	collision_layer = 0
	collision_mask = LAYER_WORLD | LAYER_PLAYER
	monitorable = false
	add_to_group("floor_switch")
	# Flat on the floor: y-sorted with the actors (a z_index below 0 would hide it under the ground tiles).
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = SIZE
	shape.shape = r
	add_child(shape)
	var frames := SpriteStrips.new_frames()
	SpriteStrips.add_strip(frames, "switch", TEX, FRAME, 1.0, false)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.animation = "switch"
	_sprite.frame = 1 if pressed else 0
	add_child(_sprite)


func _physics_process(_delta: float) -> void:
	if pressed:
		return
	for b in get_overlapping_bodies():
		if b is PushBlock or (not heavy and b is Player):
			press()
			return


func press() -> void:
	if pressed:
		return
	pressed = true
	_sprite.frame = 1
	Audio.sfx("switch_click")
	pressed_down.emit(flag)
