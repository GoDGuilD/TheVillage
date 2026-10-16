# File: PushBlock.gd
# Description: A stone block Joe can push one tile at a time by walking into it for a moment; it only moves into free floor (not walls, props or pits).
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-16
# Last edit date: 2026-10-16
# Version: 1.0.0
class_name PushBlock
extends StaticBody2D
## Joe's walk reports every body he bumps (`push(dir, delta)`); a steady push of PUSH_TIME in one direction slides
## the block one tile. Rooms reset blocks when they are rebuilt (ALttP).

signal moved(cell_pos: Vector2)

const TEX := preload("res://assets/sprites/dungeon/push_block.png")
const TILE := 16.0
const SIZE := Vector2(16, 16)
const PUSH_TIME := 0.35                  # s of steady pushing before it gives
const SLIDE_TIME := 0.25
const LAYER_WORLD := 1
const LAYER_PROPS := 128
const LAYER_PIT := 256
const PROBE_SIZE := Vector2(12, 12)
const SWITCH_SNAP := 4.0                 # px: the block rests on a switch when this close to its centre

var sliding := false
var pushes := 0

var _push_dir := Vector2.ZERO
var _push_time := 0.0
var _last_push_frame := -10


func _ready() -> void:
	collision_layer = LAYER_WORLD
	collision_mask = 0
	add_to_group("push_block")
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = SIZE
	shape.shape = r
	add_child(shape)
	var s := Sprite2D.new()
	s.texture = TEX
	add_child(s)


# Joe walked into the block this physics frame along `dir` (a cardinal unit vector).
func push(dir: Vector2, delta: float) -> void:
	if sliding:
		return
	var frame := Engine.get_physics_frames()
	if dir != _push_dir or frame - _last_push_frame > 2:
		_push_dir = dir
		_push_time = 0.0
	_last_push_frame = frame
	_push_time += delta
	if _push_time >= PUSH_TIME:
		_push_time = 0.0
		try_move(dir)


# Slide one tile along `dir` if the destination is free. Returns true if it moved.
func try_move(dir: Vector2) -> bool:
	var target := global_position + dir * TILE
	if not _free_at(target):
		return false
	sliding = true
	pushes += 1
	Audio.sfx("block_push")
	var tw := create_tween()
	tw.tween_property(self, "global_position", target, SLIDE_TIME)
	await tw.finished
	sliding = false
	# Pressing a switch it comes to rest on (direct check: area overlaps with a moved static body are unreliable).
	for sw in get_tree().get_nodes_in_group("floor_switch"):
		if (sw as Node2D).global_position.distance_to(global_position) < SWITCH_SNAP:
			sw.call("press")
	moved.emit(global_position)
	return true


func _free_at(at: Vector2) -> bool:
	var q := PhysicsShapeQueryParameters2D.new()
	var r := RectangleShape2D.new()
	r.size = PROBE_SIZE
	q.shape = r
	q.transform = Transform2D(0.0, at)
	q.collision_mask = LAYER_WORLD | LAYER_PROPS | LAYER_PIT
	q.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(q, 1).is_empty()
