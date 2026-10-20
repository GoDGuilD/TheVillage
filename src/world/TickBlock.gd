# File: TickBlock.gd
# Description: A clockwork tick block of Tempus - amber or teal; on every tick of the World's broken clock one colour rises (solid) and the other sinks into the floor (walkable).
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-23
# Last edit date: 2026-10-23
# Version: 1.0.0
class_name TickBlock
extends StaticBody2D
## Group "tick_block". The World calls `set_raised()` on every tick. A block never rises under Joe: it waits
## (`pending`) until he has stepped off. Sunk blocks move their node to the top of the cell (like pounded pegs) so
## actors walking over them are drawn on top.

const TEX := {
	true: [preload("res://assets/sprites/dungeon/tick_a_down.png"), preload("res://assets/sprites/dungeon/tick_a_up.png")],
	false: [preload("res://assets/sprites/dungeon/tick_b_down.png"), preload("res://assets/sprites/dungeon/tick_b_up.png")],
}
const SIZE := Vector2(16, 16)
const SUNK_LIFT := 9.0
const PROBE := Vector2(14, 14)           # the box checked for Joe before rising
const LAYER_WORLD := 1
const LAYER_PLAYER := 2

var amber := true                        # amber blocks are up on even ticks, teal ones on odd ticks
var raised := true
var pending := false                     # wants to rise, Joe is in the way

var _sprite: Sprite2D
var _shape: CollisionShape2D
var _cell_pos := Vector2.ZERO


func setup(is_amber: bool) -> void:
	amber = is_amber


func _ready() -> void:
	add_to_group("tick_block")
	_cell_pos = position
	collision_layer = LAYER_WORLD
	collision_mask = 0
	_shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = SIZE
	_shape.shape = r
	add_child(_shape)
	_sprite = Sprite2D.new()
	add_child(_sprite)
	_show(raised)


func set_raised(on: bool) -> void:
	if on and _joe_inside():
		pending = true
		_show(false)
		return
	pending = false
	_show(on)


func _physics_process(_delta: float) -> void:
	if pending and not _joe_inside():
		pending = false
		_show(true)


func _show(on: bool) -> void:
	raised = on
	_shape.set_deferred("disabled", not on)
	_sprite.texture = TEX[amber][1 if on else 0]
	position = _cell_pos if on else _cell_pos - Vector2(0, SUNK_LIFT)
	_sprite.position = Vector2.ZERO if on else Vector2(0, SUNK_LIFT)


# True when Joe's body overlaps this block's cell.
func _joe_inside() -> bool:
	if not is_inside_tree():
		return false
	var q := PhysicsShapeQueryParameters2D.new()
	var r := RectangleShape2D.new()
	r.size = PROBE
	q.shape = r
	q.transform = Transform2D(0.0, _cell_pos)
	q.collision_mask = LAYER_PLAYER
	return not get_world_2d().direct_space_state.intersect_shape(q, 1).is_empty()
