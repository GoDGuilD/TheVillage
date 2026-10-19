# File: IceBolt.gd
# Description: The Ice Rod's bolt - a spinning shard of ice that freezes the enemies it hits and turns every lava cell it flies over into a crust Joe can walk on for a few seconds.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-22
# Last edit date: 2026-10-22
# Version: 1.0.0
extends CharacterBody2D
## Like the fireball: flies straight until a wall or MAX_DISTANCE. Lava is not a wall (only enemies collide with
## it), so the bolt crosses it and freezes it on the way (AreaBuilder.freeze_at). HitBox element "ice".

const TEX := "res://assets/sprites/items/ice_bolt.png"
const FRAME := Vector2i(12, 12)
const FPS := 14.0
const SPEED := 220.0
const HEIGHT := 8.0
const MAX_DISTANCE := 136.0              # eight and a half tiles (the level lint uses ICE_REACH = 8)
const CRUST_TIME := 6.0                  # s the frozen lava holds
const ICE_ELEMENT := "ice"
const LAYER_WORLD := 1
const LAYER_PLAYER_HITBOX := 8

var direction := Vector2.RIGHT
var hit_box: HitBox
var frozen_cells := 0                    # lava cells this bolt froze (tests)

var _gone := 0.0


func _ready() -> void:
	add_to_group("ice_bolt")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 0
	collision_mask = LAYER_WORLD
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 3.0
	shape.shape = c
	add_child(shape)
	var frames := SpriteStrips.new_frames()
	SpriteStrips.add_strip(frames, "spin", TEX, FRAME, FPS, true)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.position = Vector2(0, -HEIGHT)
	sprite.play("spin")
	add_child(sprite)
	hit_box = HitBox.new()
	hit_box.collision_layer = LAYER_PLAYER_HITBOX
	hit_box.collision_mask = 0
	hit_box.damage = 0
	hit_box.element = ICE_ELEMENT
	var hs := CollisionShape2D.new()
	var hc := CircleShape2D.new()
	hc.radius = 5.0
	hs.shape = hc
	hs.position = Vector2(0, -HEIGHT)
	hit_box.add_child(hs)
	add_child(hit_box)
	hit_box.set_active(true)
	hit_box.landed.connect(func(_hb: HurtBox) -> void: burst())


func _physics_process(delta: float) -> void:
	if AreaBuilder.freeze_at(get_tree(), global_position, CRUST_TIME):
		frozen_cells += 1
	var step := direction * SPEED * delta
	var hit := move_and_collide(step)
	_gone += step.length()
	if hit != null or _gone >= MAX_DISTANCE:
		burst()


func burst() -> void:
	if is_queued_for_deletion():
		return
	hit_box.set_active(false)
	Juice.play_fx("hit_spark", global_position + Vector2(0, -HEIGHT), get_parent())
	queue_free()
