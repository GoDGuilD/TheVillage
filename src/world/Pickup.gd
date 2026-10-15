# File: Pickup.gd
# Description: Collectable drop (recovery heart or a green/blue/red gem): pops out, bobs, blinks before vanishing, applied when Joe touches it.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
extends Area2D
## `kind` is "heart" or a key of GameState.GEM_VALUES. Detects the Player body layer only.

signal collected(kind: String)

const PROP_DIR := "res://assets/sprites/props/"
const HEART_HEAL := 2                    # half-heart units (one full heart, as in ALttP)
const LIFETIME := 10.0                   # seconds before an uncollected drop disappears
const BLINK_FROM := 3.0                  # starts blinking this long before vanishing
const BLINK_HZ := 10.0
const POP_HEIGHT := 8.0                  # little hop when it appears
const POP_TIME := 0.25
const ARM_TIME := 0.1                    # cannot be collected in the first instant (lets the pop show)
const GEM_FRAME := Vector2i(10, 14)
const GEM_FPS := 3.0
const LAYER_PLAYER := 2
const PICK_RADIUS := 6.0

var kind := "heart"
var _age := 0.0
var _sprite: Node2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = LAYER_PLAYER
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PICK_RADIUS
	shape.shape = circle
	add_child(shape)
	if kind == "heart":
		var s := Sprite2D.new()
		s.texture = load(PROP_DIR + "heart.png")
		_sprite = s
	else:
		var a := AnimatedSprite2D.new()
		var frames := SpriteStrips.new_frames()
		SpriteStrips.add_strip(frames, "shine", PROP_DIR + kind + ".png", GEM_FRAME, GEM_FPS, true)
		a.sprite_frames = frames
		a.play("shine")
		_sprite = a
	add_child(_sprite)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_age += delta
	# Pop: a small parabola on the sprite only (the pickup area stays on the ground).
	var t := clampf(_age / POP_TIME, 0.0, 1.0)
	_sprite.position.y = -POP_HEIGHT * 4.0 * t * (1.0 - t)
	var left := LIFETIME - _age
	if left <= 0.0:
		queue_free()
		return
	_sprite.visible = left > BLINK_FROM or int(left * BLINK_HZ) % 2 == 0
	if _age >= ARM_TIME:
		for b in get_overlapping_bodies():
			_on_body_entered(b)


func _on_body_entered(body: Node) -> void:
	if _age < ARM_TIME or is_queued_for_deletion() or not body.has_method("collect"):
		return
	body.collect(kind)
	collected.emit(kind)
	queue_free()
