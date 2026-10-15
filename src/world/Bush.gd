# File: Bush.gd
# Description: Bush: blocks walking until a sword slash cuts it (leaf burst) or Joe lifts it to throw.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.1.0
class_name Bush
extends StaticBody2D
## Origin = the centre of the 16x16 tile it stands on. Lives on the Props physics layer (value 128) so Joe collides
## with it; its HurtBox listens to the PlayerHitBox layer so only the sword (later: boomerang, bombs) cuts it.

signal cut(at: Vector2)

const BUSH_TEX := preload("res://assets/sprites/world/bush.png")
const LEAF_TEX := preload("res://assets/sprites/world/leaf_burst.png")
const LEAF_FRAME := Vector2i(32, 32)
const LEAF_FPS := 14.0
const SOLID_BOX := Vector2(14, 12)
const LAYER_CUTTABLE := 128
const LAYER_PLAYER_HITBOX := 8

var _gone := false


func _ready() -> void:
	add_to_group("liftable")
	collision_layer = LAYER_CUTTABLE
	collision_mask = 0
	var spr := Sprite2D.new()
	spr.texture = BUSH_TEX
	add_child(spr)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SOLID_BOX
	shape.shape = rect
	shape.position = Vector2(0, 1)
	add_child(shape)
	var hb := HurtBox.new()
	hb.collision_layer = 0
	hb.collision_mask = LAYER_PLAYER_HITBOX
	var hs := CollisionShape2D.new()
	hs.name = "Shape"
	var hr := RectangleShape2D.new()
	hr.size = SOLID_BOX
	hs.shape = hr
	hb.add_child(hs)
	add_child(hb)
	hb.hurt.connect(_on_hurt)


func is_cut() -> bool:
	return _gone


func _on_hurt(_damage: int, _from: Vector2, _kb: Vector2) -> void:
	if _gone:
		return
	_gone = true
	cut.emit(global_position)
	Audio.sfx("bush_cut")
	_spawn_leaves()
	queue_free()


# Liftable contract: Joe pulls the bush out of the ground to throw it.
func lift() -> Dictionary:
	_gone = true
	queue_free()
	return {"kind": "bush", "texture": BUSH_TEX}


func can_lift() -> bool:
	return not _gone


# One-shot leaf burst left in the parent after the bush is gone.
func _spawn_leaves() -> void:
	var frames := SpriteStrips.new_frames()
	frames.add_animation("burst")
	frames.set_animation_speed("burst", LEAF_FPS)
	frames.set_animation_loop("burst", false)
	for i in LEAF_TEX.get_width() / LEAF_FRAME.x:
		var at := AtlasTexture.new()
		at.atlas = LEAF_TEX
		at.region = Rect2(i * LEAF_FRAME.x, 0, LEAF_FRAME.x, LEAF_FRAME.y)
		frames.add_frame("burst", at)
	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = frames
	fx.position = position                  # same parent as the bush, so the local position matches
	fx.animation_finished.connect(fx.queue_free)
	get_parent().add_child.call_deferred(fx)
	fx.play.call_deferred("burst")
