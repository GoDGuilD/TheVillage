# File: Fireball.gd
# Description: A fireball from the fire rod - flies straight, burns the first enemy it hits (fire element, 4 damage), lights any unlit torch it passes and bursts on walls.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-19
# Last edit date: 2026-10-19
# Version: 1.0.0
extends CharacterBody2D
## The HitBox carries element "fire": the Frost Wraith only takes damage from it.

const TEX := "res://assets/sprites/items/fireball.png"
const FRAME := Vector2i(12, 12)
const FPS := 14.0
const SPEED := 200.0
const DAMAGE := 4
const KNOCKBACK := 120.0
const HEIGHT := 8.0
const MAX_DISTANCE := 320.0
const TORCH_REACH := 12.0                # px: a torch this close to the flame catches fire
const FIRE_ELEMENT := "fire"
const LAYER_WORLD := 1
const LAYER_PLAYER_HITBOX := 8

var direction := Vector2.RIGHT
var hit_box: HitBox

var _gone := 0.0


func _ready() -> void:
	add_to_group("fireball")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 0
	collision_mask = LAYER_WORLD
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 3.0
	shape.shape = c
	add_child(shape)
	var frames := SpriteStrips.new_frames()
	SpriteStrips.add_strip(frames, "burn", TEX, FRAME, FPS, true)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.position = Vector2(0, -HEIGHT)
	sprite.play("burn")
	add_child(sprite)
	hit_box = HitBox.new()
	hit_box.collision_layer = LAYER_PLAYER_HITBOX
	hit_box.collision_mask = 0
	hit_box.damage = DAMAGE
	hit_box.element = FIRE_ELEMENT
	hit_box.knockback = Vector2(KNOCKBACK, 0)
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
	var torch := ItemUse.torch_near(get_tree(), global_position + Vector2(0, -HEIGHT))
	if torch != null:
		torch.call("light")
		burst()
		return
	var step := direction * SPEED * delta
	var hit := move_and_collide(step)
	_gone += step.length()
	if hit != null or _gone >= MAX_DISTANCE:
		burst()


func burst() -> void:
	if is_queued_for_deletion():
		return
	hit_box.set_active(false)
	Juice.play_fx("flame", global_position + Vector2(0, -HEIGHT), get_parent())
	queue_free()
