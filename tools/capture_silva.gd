# File: capture_silva.gd
# Description: Windowed capture script for Phase 12: the Thorn Woods' pegged west edge, the Silva Tangle with Joe swimming the river, a snapvine lunging, the Grove's pool-barred hall and pegged west room, the Thornheart closed (seeds flying) and open, and the item menu with the flippers and four crystals; saves tmp/silva_*.png.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-20
# Last edit date: 2026-10-20
# Version: 1.0.0
# Run (NOT headless - headless cannot render):  Godot_console --path . -s tools/capture_silva.gd
extends SceneTree
## Uses a throw-away save path; Joe's hurt box is off so enemies cannot spoil the shots.

const WORLD_SCENE := "res://src/world/World.tscn"
const OUT := "res://tmp/"
const CAPTURE_SAVE := "user://capture_silva_save.json"

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
	await _go("dw_west_woods", [6, 13], Vector2i.LEFT)
	await _frames(10)
	await _shot("silva_woods_pegs")
	_w.grant("flippers")
	await _go("dw_silva_tangle", [12, 10], Vector2i.LEFT)
	_p._input_override = Vector2.LEFT
	await _frames(40)
	_p._input_override = Vector2.ZERO
	await _frames(20)
	await _shot("silva_tangle_swim")
	await _go("dw_silva_tangle", [13, 16], Vector2i.UP)
	for i in 40:
		await _frames(1)
		var lunging := false
		for e in _w.current["enemies"]:
			if is_instance_valid(e) and e.get("state") == "hold":
				lunging = true
		if lunging:
			break
	await _shot("silva_snapvine_lunge")
	await _go("d7_hall", [11, 7], Vector2i.UP)
	await _frames(10)
	await _shot("silva_grove_hall")
	await _go("d7_west", [9, 8], Vector2i.LEFT)
	await _frames(10)
	await _shot("silva_grove_west")
	await _go("d7_boss", [11, 11], Vector2i.UP)
	await _frames(130)
	await _shot("silva_thornheart")
	await _go("d7_boss", [8, 6], Vector2i.RIGHT)
	for e in _w.current["enemies"]:
		if e.get("is_boss"):
			var hb := HitBox.new()
			hb.element = "fire"
			e.hurt_box.last_hit = hb
			e._on_hurt(4, e.global_position, Vector2.ZERO)
	await _frames(12)
	await _shot("silva_thornheart_open")
	for i in _gs.CRYSTAL_COUNT:
		_gs.crystals[i] = true
	_gs.give_item("glove")
	_gs.give_item("boots")
	_w.item_menu.open()
	await _frames(6)
	await _shot("silva_item_menu")
	SaveGame.delete()
	quit(0)


func _go(area: String, cell: Array, facing: Vector2i = Vector2i.DOWN) -> void:
	_p._input_override = Vector2.ZERO
	_p.end_hold()
	_w._enter(area, _w.cell_feet(area, cell), facing)
	_p.facing = facing
	_p.unfreeze()
	await _frames(6)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("saved ", name)
