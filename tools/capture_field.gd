# File: capture_field.gd
# Description: Windowed capture script: loads the test field, walks Joe, swings the sword at a bush and saves screenshots to tmp/.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
# Run (NOT headless - headless cannot render):  Godot_console --path . -s tools/capture_field.gd
extends SceneTree

const FIELD_SCENE := "res://src/world/TestField.tscn"
const OUT := "res://tmp/"

var _field: Node2D
var _p


func _initialize() -> void:
	_field = load(FIELD_SCENE).instantiate()
	root.add_child(_field)
	await process_frame
	_p = _field.player
	await _frames(10)
	await _shot("field_idle")
	_p._input_override = Vector2.LEFT
	await _frames(20)
	await _shot("field_walk")
	_p._input_override = Vector2.ZERO
	# Stand right above the bush at cell (6,20) and slash it.
	_p.global_position = Vector2(6 * 16 + 8, 20 * 16 - 2)
	_p.facing = Vector2i.DOWN
	await _frames(4)
	Input.action_press("attack")
	await _frames(5)
	Input.action_release("attack")
	await _shot("field_slash")
	await _frames(1)
	await _shot("field_leaves")
	quit(0)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("saved ", name)
