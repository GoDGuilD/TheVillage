# File: HammerBlow.gd
# Description: One swing of the Hammer - a short, heavy hit one tile in front of Joe that pounds pegs flat, flips armoured cogbugs, cracks the clock warden's armour and hurts everything else.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-23
# Last edit date: 2026-10-23
# Version: 1.0.0
extends Node2D
## Spawned by ItemUse at the impact point; lives ACTIVE_TIME s. HitBox element "hammer".

const TEX := "res://assets/sprites/items/hammer_swing.png"
const FRAME := Vector2i(24, 24)
const FPS := 20.0
const DAMAGE := 4
const KNOCKBACK := 140.0
const RADIUS := 8.0
const HEIGHT := 6.0
const ACTIVE_TIME := 0.15
const PEG_REACH := 12.0                  # px from the impact point to a peg's centre
const HAMMER_ELEMENT := "hammer"
const LAYER_PLAYER_HITBOX := 8

var direction := Vector2.DOWN
var hit_box: HitBox
var pounded := 0                         # pegs flattened by this blow (tests)

var _age := 0.0


func _ready() -> void:
	add_to_group("hammer_blow")
	var frames := SpriteStrips.new_frames()
	SpriteStrips.add_strip(frames, "swing", TEX, FRAME, FPS, false)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.position = Vector2(0, -HEIGHT)
	sprite.rotation = direction.angle() - PI / 2.0
	sprite.play("swing")
	add_child(sprite)
	hit_box = HitBox.new()
	hit_box.collision_layer = LAYER_PLAYER_HITBOX
	hit_box.collision_mask = 0
	hit_box.damage = DAMAGE
	hit_box.element = HAMMER_ELEMENT
	hit_box.knockback = Vector2(KNOCKBACK, 0)
	var s := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = RADIUS
	s.shape = c
	s.position = Vector2(0, -HEIGHT)
	hit_box.add_child(s)
	add_child(hit_box)
	hit_box.set_active(true)
	Audio.sfx("pound")
	Juice.shake(1.5, 0.1)
	for p in get_tree().get_nodes_in_group("peg"):
		var peg := p as Node2D
		if peg != null and peg.global_position.distance_to(global_position) <= PEG_REACH and peg.call("pound"):
			pounded += 1


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= ACTIVE_TIME:
		hit_box.set_active(false)
		queue_free()
