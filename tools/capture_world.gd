# File: capture_world.gd
# Description: Windowed capture script for the overworld: Joe's house, the village, a screen scroll in progress, each neighbouring area and the ledge hop; saves tmp/world_*.png.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
# Run (NOT headless - headless cannot render):  Godot_console --path . -s tools/capture_world.gd
extends SceneTree
## Joe's hurt box is switched off so enemies cannot spoil a scripted shot; every step guards against freed nodes.

const WORLD_SCENE := "res://src/world/World.tscn"
const OUT := "res://tmp/"

var _w
var _p


func _initialize() -> void:
	root.get_node("GameState").drops_enabled = false
	_w = load(WORLD_SCENE).instantiate()
	root.add_child(_w)
	await process_frame
	_p = _w.player
	_p.hurt_box.set_deferred("monitoring", false)
	await _frames(10)
	await _shot("world_house")
	await _go("el_pueblo", [8, 7])
	await _shot("world_village")
	await _go("el_pueblo", [30, 9])
	await _shot("world_village_east")
	# A scroll caught mid-slide.
	await _go("el_pueblo", [23, 2], Vector2i.UP)
	_p._input_override = Vector2.UP
	for i in 90:
		await _frames(1)
		if _w.transitioning:
			break
	_p._input_override = Vector2.ZERO
	await _frames(16)
	await _shot("world_scroll")
	await _frames(40)
	await _shot("world_meadow")
	await _go("west_woods", [12, 13])
	await _shot("world_woods")
	await _go("east_lake", [10, 13])
	await _shot("world_lake")
	await _go("south_road", [23, 4], Vector2i.DOWN)
	_p._input_override = Vector2.DOWN
	await _frames(12)
	await _shot("world_hop")
	_p._input_override = Vector2.ZERO
	await _frames(30)
	await _shot("world_south")
	quit(0)


func _go(area: String, cell: Array, facing: Vector2i = Vector2i.DOWN) -> void:
	if not is_instance_valid(_p):
		return
	_p._input_override = Vector2.ZERO
	_w._enter(area, _w.cell_feet(area, cell), facing)
	_p.unfreeze()
	await _frames(6)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("saved ", name)
