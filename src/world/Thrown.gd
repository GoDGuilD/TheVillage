# File: Thrown.gd
# Description: A lifted pot or bush flying after Joe throws it: arcs over the ground, damages what it hits, breaks on landing or on walls.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
extends CharacterBody2D
## The body (and its HitBox) moves along the ground; only the sprite rises and falls, ALttP style.

signal broke(at: Vector2)

const SHADOW_TEX := preload("res://assets/sprites/joe/joe_shadow.png")
const RADIUS := 5.0
const LAYER_WORLD := 1
const LAYER_PROPS := 128
const LAYER_PLAYER_HITBOX := 8

var kind := "pot"
var texture: Texture2D
var direction := Vector2.DOWN
var speed := 180.0
var travel := 64.0                       # px along the ground before it lands
var start_height := 22.0                 # sprite height above the ground at release
var damage := 2
var hit_box: HitBox

var _sprite: Sprite2D
var _gone := 0.0                         # distance travelled so far
var _broken := false


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 0
	collision_mask = LAYER_WORLD | LAYER_PROPS
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = RADIUS
	shape.shape = c
	add_child(shape)
	var sh := Sprite2D.new()
	sh.texture = SHADOW_TEX
	add_child(sh)
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	add_child(_sprite)
	hit_box = HitBox.new()
	hit_box.collision_layer = LAYER_PLAYER_HITBOX
	hit_box.collision_mask = 0
	hit_box.damage = damage
	hit_box.knockback = Vector2(120.0, 0.0)
	var hs := CollisionShape2D.new()
	var hc := CircleShape2D.new()
	hc.radius = RADIUS + 2.0
	hs.shape = hc
	hit_box.add_child(hs)
	add_child(hit_box)
	hit_box.set_active(true)
	hit_box.landed.connect(func(_hb: HurtBox) -> void: _break())
	_update_height()


func _physics_process(delta: float) -> void:
	if _broken:
		return
	var step := direction * speed * delta
	var hit := move_and_collide(step)
	_gone += step.length()
	_update_height()
	if hit != null or _gone >= travel:
		_break()


# Height follows a falling arc: starts at start_height, touches the ground when the travel is used up.
func _update_height() -> void:
	var t := clampf(_gone / travel, 0.0, 1.0)
	_sprite.position.y = -start_height * (1.0 - t * t)


func _break() -> void:
	if _broken:
		return
	_broken = true
	hit_box.set_active(false)
	if kind == "pot":
		Audio.sfx("shatter")
		Juice.play_fx("shards", global_position, get_parent())
		BaseEnemy.spawn_drop(get_parent(), global_position)
	else:
		Audio.sfx("bush_cut")
		Juice.play_fx("poof", global_position, get_parent())
	broke.emit(global_position)
	queue_free()
