# File: capture_umbra.gd
# Description: Windowed capture script for Phase 9: the Umbral Vale and its chasm, the grapple's chain in flight, a dark room without and with the lantern, the east room's chasm and hook posts, the Gloom Moth flying and grounded, the Shade Market, the item menu's crystal sockets and the Dark World map with the vale; saves tmp/umbra_*.png.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-21
# Last edit date: 2026-10-21
# Version: 1.0.0
# Run (NOT headless - headless cannot render):  Godot_console --path . -s tools/capture_umbra.gd
extends SceneTree
## Uses a throw-away save path; Joe's hurt box is off so enemies cannot spoil the shots.

const WORLD_SCENE := "res://src/world/World.tscn"
const OUT := "res://tmp/"
const CAPTURE_SAVE := "user://capture_umbra_save.json"

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
	_gs.give_item("grapple")
	_gs.equip("grapple")
	await _go("dw_umbra_vale", [24, 9], Vector2i.UP)
	await _frames(10)
	await _shot("umbra_vale")
	await _go("dw_umbra_vale", [29, 6], Vector2i.RIGHT)
	await _tap("item")
	await _frames(8)
	await _shot("umbra_grapple_flight")
	await _frames(60)
	await _go("d4_hall", [11, 11], Vector2i.UP)
	await _frames(10)
	await _shot("umbra_dark_room")
	_gs.give_item("lantern")
	await _go("d4_hall", [11, 11], Vector2i.UP)
	await _frames(10)
	await _shot("umbra_dark_lantern")
	await _go("d4_east", [12, 6], Vector2i.RIGHT)
	await _frames(10)
	await _shot("umbra_east_chasm")
	await _go("d4_boss", [11, 11], Vector2i.UP)
	await _frames(70)
	await _shot("umbra_moth_flying")
	var moth: Node2D = null
	for e in _w.current["enemies"]:
		if e.get("is_boss"):
			moth = e
	if moth != null:
		moth.call("_land")
	await _frames(10)
	await _shot("umbra_moth_grounded")
	await _go("dw_el_pueblo", [10, 18], Vector2i.UP)
	await _frames(10)
	await _shot("umbra_shade_market")
	_gs.crystals[0] = true
	_w.item_menu.open()
	await _frames(6)
	await _shot("umbra_item_menu")
	_w.item_menu.close()
	await _frames(4)
	await _go("dw_umbra_vale", [24, 9], Vector2i.UP)
	_w.map_screen.open(_w.areas, _w.current_id(), _w.dungeons)
	await _frames(4)
	await _shot("umbra_map")
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


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("saved ", name)
