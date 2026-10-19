# File: capture_ignis.gd
# Description: Windowed capture script for Phase 10: the Cinder Barrens and its lava river, an ice path frozen over the lava pool, a cinder and its flame, the forge's lava islet room, the Magma Wyrm up and frozen, and the item menu with two crystals; saves tmp/ignis_*.png.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-22
# Last edit date: 2026-10-22
# Version: 1.0.0
# Run (NOT headless - headless cannot render):  Godot_console --path . -s tools/capture_ignis.gd
extends SceneTree
## Uses a throw-away save path; Joe's hurt box is off so enemies cannot spoil the shots.

const WORLD_SCENE := "res://src/world/World.tscn"
const OUT := "res://tmp/"
const CAPTURE_SAVE := "user://capture_ignis_save.json"

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
	_gs.give_item("ice_rod")
	_gs.equip("ice_rod")
	await _go("dw_cinder_barrens", [3, 13], Vector2i.RIGHT)
	await _frames(10)
	await _shot("ignis_barrens_river")
	await _go("dw_cinder_barrens", [15, 15], Vector2i.DOWN)
	await _tap("item")
	await _frames(30)
	await _shot("ignis_ice_path")
	await _go("d5_west", [16, 6], Vector2i.LEFT)
	await _frames(40)
	await _shot("ignis_forge_islet")
	await _go("d5_boss", [11, 11], Vector2i.UP)
	var wyrm: Node2D = null
	for e in _w.current["enemies"]:
		if e.get("is_boss"):
			wyrm = e
	for i in 240:
		await _frames(1)
		if wyrm != null and wyrm.state == "up":
			break
	await _frames(45)
	await _shot("ignis_wyrm_up")
	if wyrm != null:
		wyrm.call("_iced")
	await _frames(6)
	await _shot("ignis_wyrm_frozen")
	_gs.crystals[0] = true
	_gs.crystals[1] = true
	_w.item_menu.open()
	await _frames(6)
	await _shot("ignis_item_menu")
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
