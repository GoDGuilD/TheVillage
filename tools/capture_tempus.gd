# File: capture_tempus.gd
# Description: Windowed capture script for Phase 11: the Clockwork Wastes (molten time, the tick fence, the pegs) on both clock phases, a hammer swing pounding a peg, the clocktower's tick-block ring, a flipped cogbug, the Clock Warden walking and cracked, and the item menu with three crystals; saves tmp/tempus_*.png.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-23
# Last edit date: 2026-10-23
# Version: 1.0.0
# Run (NOT headless - headless cannot render):  Godot_console --path . -s tools/capture_tempus.gd
extends SceneTree
## Uses a throw-away save path; Joe's hurt box is off so enemies cannot spoil the shots.

const WORLD_SCENE := "res://src/world/World.tscn"
const OUT := "res://tmp/"
const CAPTURE_SAVE := "user://capture_tempus_save.json"

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
	_gs.give_item("hammer")
	_gs.equip("hammer")
	await _go("dw_clockwork_wastes", [8, 12], Vector2i.UP)
	await _frames(10)
	await _shot("tempus_wastes_tick_a")
	await _frames(125)
	await _shot("tempus_wastes_tick_b")
	await _go("dw_clockwork_wastes", [6, 17], Vector2i.DOWN)
	await _tap("item")
	await _frames(4)
	await _shot("tempus_hammer_peg")
	await _go("d6_west", [10, 8], Vector2i.LEFT)
	await _frames(10)
	await _shot("tempus_tick_ring")
	await _go("d6_east", [16, 7], Vector2i.UP)
	for e in _w.current["enemies"]:
		e.position = _w.cell_feet("d6_east", [16, 5])
		var hb := HitBox.new()
		hb.element = "hammer"
		e.hurt_box.last_hit = hb
		e._on_hurt(4, e.global_position, Vector2.ZERO)
		break
	await _frames(10)
	await _shot("tempus_cogbug_flipped")
	await _go("d6_boss", [11, 11], Vector2i.UP)
	await _frames(80)
	await _shot("tempus_warden")
	for e in _w.current["enemies"]:
		if e.get("is_boss"):
			var hb2 := HitBox.new()
			hb2.element = "hammer"
			e.hurt_box.last_hit = hb2
			e._on_hurt(4, e.global_position, Vector2.ZERO)
	await _frames(8)
	await _shot("tempus_warden_cracked")
	_gs.crystals[0] = true
	_gs.crystals[1] = true
	_gs.crystals[2] = true
	_w.item_menu.open()
	await _frames(6)
	await _shot("tempus_item_menu")
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
