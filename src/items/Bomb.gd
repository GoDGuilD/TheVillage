# File: Bomb.gd
# Description: A lit bomb - sits where Joe set it down, flashes faster as the fuse burns, then explodes: hurts enemies and Joe, cuts bushes, breaks cracked rocks, shakes the screen.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-21
# Version: 1.0.1
extends Node2D
## Two hit boxes on the blast: one on the PlayerHitBox layer (enemies, bushes) and one on the EnemyHitBox layer
## (Joe - ALttP bombs hurt Link too; not blockable). Nodes in group "bombable" within BLAST_RADIUS get blast().

signal exploded(at: Vector2)

const TEX := "res://assets/sprites/items/bomb.png"
const FRAME := Vector2i(16, 18)
const FEET_Y := 16.0                     # bomb sprite's ground line
const FUSE := 1.6
const FLASH_FROM := 0.7                  # starts flashing this long before the blast
const FLASH_HZ := 10.0
const BLAST_RADIUS := 22.0
const BLAST_TIME := 0.12                 # hit boxes stay live this long
const ENEMY_DAMAGE := 4
const JOE_DAMAGE := 2
const KNOCKBACK := 180.0
const SHAKE := Vector2(2.5, 0.25)
const RUMBLE := Vector3(0.4, 0.7, 0.25)          # gamepad rumble of the blast: (weak, strong, seconds)
const LAYER_PLAYER_HITBOX := 8
const LAYER_ENEMY_HITBOX := 16

var fuse_left := FUSE
var has_exploded := false

var _sprite: AnimatedSprite2D
var _blast_left := 0.0
var _boxes: Array[HitBox] = []


func _ready() -> void:
	add_to_group("bomb")
	var frames := SpriteStrips.new_frames()
	SpriteStrips.add_strip(frames, "fuse", TEX, FRAME, 1.0, false)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.animation = "fuse"
	_sprite.offset = Vector2(0, float(FRAME.y) / 2.0 - FEET_Y)
	add_child(_sprite)
	for spec in [[LAYER_PLAYER_HITBOX, ENEMY_DAMAGE], [LAYER_ENEMY_HITBOX, JOE_DAMAGE]]:
		var hb := HitBox.new()
		hb.collision_layer = int(spec[0])
		hb.collision_mask = 0
		hb.damage = int(spec[1])
		hb.knockback = Vector2(KNOCKBACK, 0)
		hb.blockable = false
		var s := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = BLAST_RADIUS
		s.shape = c
		s.position = Vector2(0, -6)
		hb.add_child(s)
		add_child(hb)
		hb.set_active(false)
		_boxes.append(hb)
	Audio.sfx("bomb_place")


func _physics_process(delta: float) -> void:
	if has_exploded:
		_blast_left -= delta
		if _blast_left <= 0.0:
			queue_free()
		return
	fuse_left -= delta
	_sprite.frame = 1 if fuse_left < FLASH_FROM and int(fuse_left * FLASH_HZ * 2.0) % 2 == 0 else 0
	if fuse_left <= 0.0:
		explode()


func explode() -> void:
	if has_exploded:
		return
	has_exploded = true
	_blast_left = BLAST_TIME
	_sprite.visible = false
	for hb in _boxes:
		hb.set_active(true)
	Audio.sfx("explode")
	Juice.play_fx("explosion", global_position + Vector2(0, -6), get_parent())
	Juice.shake(SHAKE.x, SHAKE.y)
	Juice.rumble(RUMBLE.x, RUMBLE.y, RUMBLE.z)
	for n in get_tree().get_nodes_in_group("bombable"):
		var node := n as Node2D
		if node != null and node.global_position.distance_to(global_position) <= BLAST_RADIUS + 8.0:
			node.call("blast")
	exploded.emit(global_position)
