# File: EnemyShot.gd
# Description: A generic enemy projectile (the Frost Wraith's ice shards) - flies straight, hurts Joe, can be stopped by his shield, shatters on walls.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-19
# Last edit date: 2026-10-19
# Version: 1.0.0
extends CharacterBody2D
## Blockable-projectile contract: HitBox.blockable + deflect() (Joe's shield calls it).

const SPEED := 110.0
const DAMAGE := 2
const LIFETIME := 3.0
const RADIUS := 3.0
const HEIGHT := 8.0
const LAYER_WORLD := 1
const LAYER_ENEMY_HITBOX := 16

var direction := Vector2.DOWN
var texture: Texture2D
var hit_box: HitBox

var _age := 0.0


func _ready() -> void:
	add_to_group("enemy_shot")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 0
	collision_mask = LAYER_WORLD
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = RADIUS
	shape.shape = c
	add_child(shape)
	var spr := Sprite2D.new()
	spr.texture = texture
	spr.position = Vector2(0, -HEIGHT)
	add_child(spr)
	hit_box = HitBox.new()
	hit_box.collision_layer = LAYER_ENEMY_HITBOX
	hit_box.collision_mask = 0
	hit_box.damage = DAMAGE
	hit_box.blockable = true
	var hs := CollisionShape2D.new()
	var hc := CircleShape2D.new()
	hc.radius = RADIUS + 1.0
	hs.shape = hc
	hs.position = Vector2(0, -HEIGHT)
	hit_box.add_child(hs)
	add_child(hit_box)
	hit_box.set_active(true)
	hit_box.landed.connect(func(_hb: HurtBox) -> void: queue_free())


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	if move_and_collide(direction * SPEED * delta) != null:
		Juice.play_fx("hit_spark", global_position, get_parent())
		queue_free()


func deflect() -> void:
	Juice.play_fx("hit_spark", global_position, get_parent())
	queue_free()
