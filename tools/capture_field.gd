# File: capture_field.gd
# Description: Windowed capture script: plays scripted moments in the meadow (walk, slash, spin, carry/throw, enemies, HUD) and saves screenshots to tmp/.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 2.0.0
# Run (NOT headless - headless cannot render):  Godot_console --path . -s tools/capture_field.gd
extends SceneTree
## Script errors hang a windowed run, so every step guards against freed nodes (Chapel of Dreams lesson).

const FIELD_SCENE := "res://src/world/TestField.tscn"
const OUT := "res://tmp/"
const TILE := 16

var _field: Node2D
var _p


func _initialize() -> void:
	root.get_node("GameState").drops_enabled = false
	_field = load(FIELD_SCENE).instantiate()
	root.add_child(_field)
	await process_frame
	_p = _field.player
	_p.hurt_box.set_deferred("monitoring", false)       # screenshots, not a fight: enemies cannot interrupt Joe
	await _frames(10)
	await _shot("field_idle")
	# Walk left along the path.
	_p._input_override = Vector2.LEFT
	await _frames(20)
	_p._input_override = Vector2.ZERO
	await _shot("field_walk")
	# Slash a bush (cell 6,20).
	await _place(6 * TILE + 8, 20 * TILE - 2, Vector2i.DOWN)
	Input.action_press("attack")
	await _frames(5)
	Input.action_release("attack")
	await _shot("field_slash")
	await _frames(1)
	await _shot("field_leaves")
	# Spin attack on the open path west of the crossing (cell 8,13), away from patrolling guards.
	await _place(8 * TILE + 8, 14 * TILE, Vector2i.DOWN)
	Input.action_press("attack")
	await _frames(20)
	await _frames(52)
	await _shot("field_charge")
	Input.action_release("attack")
	await _frames(4)
	await _shot("field_spin")
	await _frames(20)
	# Lift a pot (cells 17-19,17) and carry it.
	await _place(17 * TILE + 8, 17 * TILE - 1, Vector2i.DOWN)
	_p.global_position = Vector2(17 * TILE + 8, 16 * TILE + 13)
	Input.action_press("interact")
	await _frames(2)
	Input.action_release("interact")
	await _frames(16)
	_p._input_override = Vector2.LEFT
	await _frames(12)
	_p._input_override = Vector2.ZERO
	await _shot("field_carry")
	Input.action_press("interact")
	await _frames(2)
	Input.action_release("interact")
	await _frames(14)
	await _shot("field_throw")
	# Look at the spitter and slime in the north-east.
	await _place(30 * TILE, 6 * TILE, Vector2i.RIGHT)
	await _frames(40)
	await _shot("field_enemies")
	quit(0)


func _place(x: float, y: float, facing: Vector2i) -> void:
	if not is_instance_valid(_p):
		return
	_p._input_override = Vector2.ZERO
	_p.revive(Vector2(x, y))
	_p.facing = facing
	await _frames(4)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("saved ", name)
