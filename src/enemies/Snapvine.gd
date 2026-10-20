# File: Snapvine.gd
# Description: The snapvine - a rooted carnivorous plant of Silva; it never moves, but when Joe comes near it winds up and lunges its jaws at him on a stretching vine, then pulls back.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-20
# Last edit date: 2026-10-20
# Version: 1.0.0
class_name Snapvine
extends BaseEnemy
## States: "wait" (head on its root; Joe within REACH px and the cooldown over -> "wind") -> "wind" (WIND_TIME s
## shaking, jaws open: the tell) -> "lunge" (the head shoots LUNGE_DIST px toward where Joe was, in LUNGE_TIME s)
## -> "hold" (HOLD_TIME s) -> "back" (RETURN_TIME s) -> "wait" with COOLDOWN s before the next lunge.
## The head carries the sprite, the hurt box and the contact box; the vine between root and head is drawn here.

const ROOT_TEX := preload("res://assets/sprites/items/snapvine_root.png")
const REACH := 44.0
const LUNGE_DIST := 30.0
const WIND_TIME := 0.4
const LUNGE_TIME := 0.1
const HOLD_TIME := 0.15
const RETURN_TIME := 0.35
const COOLDOWN := 0.9
const SHAKE_PX := 1.0                    # the wind-up's tremble
const ROOT_OFFSET := Vector2(0, -4)      # the root leaves sit on the feet
const NECK_FROM := Vector2(0, -6)        # where the vine leaves the root
const NECK_WIDTH := 3.0
const NECK_COLOR := Color("3c8030")      # palette VINE_MID (gen_silva.py)
const NECK_EDGE := Color("1c4820")       # palette VINE_DARK
const HEAD_OVER_AT := 4.0                # px out from the root: past this the head is drawn over everything (it
                                         # bites Joe, whose feet may sort below its root)

var state := "wait"
var lunges := 0                          # lunges started (tests)
var head := Vector2.ZERO                 # the head's offset from the root

var _timer := 0.0
var _cooldown := 0.0
var _aim := Vector2.DOWN


func _init() -> void:
	pack = "snapvine"
	max_hp = 4
	contact_damage = 2
	body_size = Vector2(14, 14)
	body_center = Vector2(0, -9)


func _ready() -> void:
	super._ready()
	var root := Sprite2D.new()
	root.name = "Root"
	root.texture = ROOT_TEX
	root.position = ROOT_OFFSET
	add_child(root)
	move_child(root, 0)                  # drawn under the head


func _anim_base() -> String:
	return "idle"


# Rooted: hits never push it.
func _on_hurt(damage: int, source_position: Vector2, _knockback: Vector2) -> void:
	super._on_hurt(damage, source_position, Vector2.ZERO)


func _think(delta: float) -> void:
	_move(Vector2.ZERO)
	_cooldown = maxf(0.0, _cooldown - delta)
	match state:
		"wait":
			var to := _to_player()
			if _cooldown <= 0.0 and to != Vector2.INF and to.length() <= REACH:
				state = "wind"
				_timer = WIND_TIME
				_aim = to.normalized() if to.length() > 0.01 else Vector2.DOWN
				_play("bite")
		"wind":
			_timer -= delta
			_set_head(Vector2(SHAKE_PX * (1.0 if int(_timer * 40.0) % 2 == 0 else -1.0), 0.0))
			if _timer <= 0.0:
				state = "lunge"
				_timer = LUNGE_TIME
				lunges += 1
				Audio.sfx("snap")
		"lunge":
			_timer -= delta
			_set_head(_aim * LUNGE_DIST * clampf(1.0 - _timer / LUNGE_TIME, 0.0, 1.0))
			if _timer <= 0.0:
				state = "hold"
				_timer = HOLD_TIME
		"hold":
			_timer -= delta
			if _timer <= 0.0:
				state = "back"
				_timer = RETURN_TIME
		"back":
			_timer -= delta
			_set_head(_aim * LUNGE_DIST * clampf(_timer / RETURN_TIME, 0.0, 1.0))
			if _timer <= 0.0:
				state = "wait"
				_cooldown = COOLDOWN
				_set_head(Vector2.ZERO)
				_play("idle")


# Move the head (sprite, hurt box, contact box) to `offset` from the root and redraw the vine.
func _set_head(offset: Vector2) -> void:
	head = offset
	sprite.position = offset
	hurt_box.position = offset
	contact.position = offset
	sprite.z_index = 1 if offset.length() > HEAD_OVER_AT else 0
	queue_redraw()


func _draw() -> void:
	if head.length() < 1.0:
		return
	var tip := head + body_center + Vector2(0, 4)
	draw_line(NECK_FROM, tip, NECK_EDGE, NECK_WIDTH + 2.0)
	draw_line(NECK_FROM, tip, NECK_COLOR, NECK_WIDTH)
