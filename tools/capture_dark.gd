# File: capture_dark.gd
# Description: Windowed capture script for Phase 8: Hollow Pueblo with Tato's echo, the Withered Meadow's dry pond, a mirror warp's shimmer in the Light World, a dream rift, and the Dark World map; saves tmp/dark_*.png.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-20
# Last edit date: 2026-10-20
# Version: 1.0.0
# Run (NOT headless - headless cannot render):  Godot_console --path . -s tools/capture_dark.gd
extends SceneTree
## Uses a throw-away save path; Joe's hurt box is off so enemies cannot spoil the shots.

const WORLD_SCENE := "res://src/world/World.tscn"
const OUT := "res://tmp/"
const CAPTURE_SAVE := "user://capture_dark_save.json"

var _gs
var _w
var _p


func _initialize() -> void:
	_gs = root.get_node("GameState")
	_gs.reset()
	_gs.drops_enabled = false
	_gs.set_flag("act1:done")
	_gs.set_flag("act2:started")
	SaveGame.path = CAPTURE_SAVE
	_w = load(WORLD_SCENE).instantiate()
	root.add_child(_w)
	await process_frame
	_p = _w.player
	_p.hurt_box.set_deferred("monitoring", false)
	_gs.give_item("moon_mirror")
	_gs.equip("moon_mirror")
	await _go("dw_el_pueblo", [19, 13], Vector2i.UP)
	await _frames(10)
	await _shot("dark_pueblo")
	await _go("dw_meadow_north", [34, 6], Vector2i.UP)
	await _frames(10)
	await _shot("dark_meadow_dry_pond")
	await _go("dw_meadow_north", [34, 3], Vector2i.DOWN)
	await _frames(10)
	await _tap("item")
	await _frames(40)
	await _shot("dark_mirror_island")
	await _close()
	await _go("el_pueblo", [20, 15], Vector2i.DOWN)
	await _frames(10)
	await _shot("dark_rift")
	await _go("dw_el_pueblo", [23, 14])
	_w.map_screen.open(_w.areas, _w.current_id(), _w.dungeons)
	await _frames(4)
	await _shot("dark_map")
	SaveGame.delete()
	quit(0)


func _go(area: String, cell: Array, facing: Vector2i = Vector2i.DOWN) -> void:
	_p._input_override = Vector2.ZERO
	_p.end_hold()
	_w._enter(area, _w.cell_feet(area, cell), facing)
	_p.facing = facing
	_p.unfreeze()
	await _frames(6)


func _tap(action: String) -> void:
	Input.action_press(action)
	await _frames(2)
	Input.action_release(action)
	await _frames(1)


func _close() -> void:
	var guard := 0
	while _w.dialogue.is_open and guard < 30:
		guard += 1
		_w.dialogue.advance()
		await process_frame
	await _frames(15)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("saved ", name)
