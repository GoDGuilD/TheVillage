# File: Rift.gd
# Description: A dream rift (Light World) or the Moon Mirror's shimmer - a swirling patch that sends Joe to the other world at the same spot when he steps onto it.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-20
# Last edit date: 2026-10-20
# Version: 1.0.1
class_name Rift
extends Area2D
## Two uses: permanent dream rifts in the Light World (shown once Act 1 is over) and the one-off portal the Moon
## Mirror leaves where Joe lands. A portal only arms once Joe has stepped off it (he arrives standing on it).

signal entered(rift: Node2D)

const RIFT_TEX := "res://assets/sprites/world/rift.png"
const PORTAL_TEX := "res://assets/sprites/world/portal.png"
const FRAME := Vector2i(16, 16)
const FPS := 8.0
const RADIUS := 5.0
const LAYER_PLAYER := 2

var portal := false                      # true = the mirror's shimmer (arms after Joe steps off)
var armed := true

var _sprite: AnimatedSprite2D


func setup(is_portal: bool) -> void:
	portal = is_portal
	armed = not is_portal


func _ready() -> void:
	add_to_group("rift")
	collision_layer = 0
	collision_mask = LAYER_PLAYER
	monitorable = false
	# Flat on the floor: y-sorted with the actors (a z_index below 0 would hide it under the ground tiles).
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = RADIUS
	shape.shape = c
	add_child(shape)
	var frames := SpriteStrips.new_frames()
	SpriteStrips.add_strip(frames, "swirl", PORTAL_TEX if portal else RIFT_TEX, FRAME, FPS, true)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.play("swirl")
	add_child(_sprite)
	body_exited.connect(func(b: Node) -> void:
		if b is Player:
			armed = true)


func _physics_process(_delta: float) -> void:
	if not armed:
		return
	for b in get_overlapping_bodies():
		if b is Player:
			armed = false
			entered.emit(self)
			return
