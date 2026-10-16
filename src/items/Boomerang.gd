# File: Boomerang.gd
# Description: Joe's boomerang - spins out up to 6 tiles (straight or diagonal), turns back at a wall, an enemy or the end of its range, stuns what it hits, and carries pickups back to Joe.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
extends CharacterBody2D
## Only one flies at a time (group "boomerang"). Its HitBox has element "stun": BaseEnemy freezes instead of
## taking damage; bushes (PlayerHitBox listeners) are cut, as in ALttP.

signal returned

const TEX := "res://assets/sprites/items/boomerang_spin.png"
const FRAME := Vector2i(14, 14)
const SPIN_FPS := 20.0
const SPEED := 200.0
const RETURN_SPEED := 220.0
const RANGE := 96.0                      # six tiles out
const HEIGHT := 9.0                      # flies at chest height (sprite only)
const RADIUS := 4.0
const CATCH_DISTANCE := 8.0              # back in Joe's hands
const GRAB_DISTANCE := 10.0              # pickups this close latch on
const WHIRR_EVERY := 0.18
const LAYER_WORLD := 1
const LAYER_PLAYER_HITBOX := 8
const STUN_ELEMENT := "stun"

var direction := Vector2.RIGHT
var owner_node: Node2D                   # Joe
var coming_back := false
var carried: Array = []                  # pickups riding home

var _gone := 0.0
var _whirr := 0.0
var hit_box: HitBox


func _ready() -> void:
	add_to_group("boomerang")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 0
	collision_mask = LAYER_WORLD
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = RADIUS
	shape.shape = c
	add_child(shape)
	var sprite := AnimatedSprite2D.new()
	var frames := SpriteStrips.new_frames()
	SpriteStrips.add_strip(frames, "spin", TEX, FRAME, SPIN_FPS, true)
	sprite.sprite_frames = frames
	sprite.position = Vector2(0, -HEIGHT)
	sprite.play("spin")
	add_child(sprite)
	hit_box = HitBox.new()
	hit_box.collision_layer = LAYER_PLAYER_HITBOX
	hit_box.collision_mask = 0
	hit_box.damage = 0
	hit_box.element = STUN_ELEMENT
	var hs := CollisionShape2D.new()
	var hc := CircleShape2D.new()
	hc.radius = RADIUS + 3.0
	hs.shape = hc
	hs.position = Vector2(0, -HEIGHT)
	hit_box.add_child(hs)
	add_child(hit_box)
	hit_box.set_active(true)
	hit_box.landed.connect(func(_hb: HurtBox) -> void: turn_back())


func turn_back() -> void:
	coming_back = true


func _physics_process(delta: float) -> void:
	_whirr -= delta
	if _whirr <= 0.0:
		_whirr = WHIRR_EVERY
		Audio.sfx("boomerang")
	_grab_pickups()
	if not coming_back:
		var step := direction * SPEED * delta
		var hit := move_and_collide(step)
		_gone += step.length()
		if hit != null:
			Audio.sfx("arrow_hit", 1.3)
			turn_back()
		elif _gone >= RANGE:
			turn_back()
		return
	# Homing back through walls (ALttP's boomerang never gets stuck).
	if owner_node == null or not is_instance_valid(owner_node):
		queue_free()
		return
	var target := owner_node.global_position + Vector2(0, -2)
	var to := target - global_position
	if to.length() <= CATCH_DISTANCE:
		_catch()
		return
	global_position += to.normalized() * minf(RETURN_SPEED * delta, to.length())


# Pickups the boomerang touches ride along with it.
func _grab_pickups() -> void:
	for p in get_tree().get_nodes_in_group("pickup"):
		var node := p as Node2D
		if node == null or carried.has(node) or node.is_queued_for_deletion():
			continue
		if node.global_position.distance_to(global_position) <= GRAB_DISTANCE:
			carried.append(node)
			turn_back()
	for node in carried:
		if is_instance_valid(node):
			node.global_position = global_position


func _catch() -> void:
	for node in carried:
		if is_instance_valid(node) and owner_node.has_method("collect"):
			node.global_position = owner_node.global_position     # Joe's body is now inside it
	returned.emit()
	queue_free()
