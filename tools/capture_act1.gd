# File: capture_act1.gd
# Description: Windowed capture script for Phase 7: the South Fields and the keep's seal gate, a dash, a fireball, the Iron Ram, the Frost Wraith, Caver's shade and the end-of-act card; saves tmp/act1_*.png.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-19
# Last edit date: 2026-10-19
# Version: 1.0.0
# Run (NOT headless - headless cannot render):  Godot_console --path . -s tools/capture_act1.gd
extends SceneTree
## Uses a throw-away save path; Joe's hurt box is off so enemies cannot spoil the shots.

const WORLD_SCENE := "res://src/world/World.tscn"
const OUT := "res://tmp/"
const CAPTURE_SAVE := "user://capture_act1_save.json"

var _gs
var _w
var _p


func _initialize() -> void:
	_gs = root.get_node("GameState")
	_gs.reset()
	_gs.drops_enabled = false
	SaveGame.path = CAPTURE_SAVE
	_w = load(WORLD_SCENE).instantiate()
	root.add_child(_w)
	await process_frame
	_p = _w.player
	_p.hurt_box.set_deferred("monitoring", false)
	for item in ["glove", "boots", "fire_rod", "bombs", "bow"]:
		_gs.give_item(item)
	_gs.seals[0] = true
	_gs.seals[1] = true
	await _go("south_fields", [16, 9], Vector2i.UP)
	await _frames(10)
	await _shot("act1_keep_gate")
	await _go("south_fields", [40, 21], Vector2i.UP)
	await _frames(10)
	await _shot("act1_vault_fence")
	await _go("south_fields", [8, 21], Vector2i.RIGHT)
	await _tap("dash")
	await _frames(30)
	await _shot("act1_dash")
	_gs.equip("fire_rod")
	await _go("d3_west", [6, 7], Vector2i.UP)
	await _tap("item")
	await _frames(10)
	await _shot("act1_fireball")
	await _go("d2_boss", [11, 10], Vector2i.UP)
	await _frames(70)
	await _shot("act1_iron_ram")
	await _go("d3_boss", [11, 10], Vector2i.UP)
	await _frames(170)
	await _shot("act1_frost_wraith")
	await _go("keep_throne", [11, 10], Vector2i.UP)
	await _frames(80)
	await _shot("act1_caver")
	_w.end_card.open("END OF ACT ONE", DialogueData.pages_for("act1_card", _gs))
	await _frames(int(60 * 6.5))
	await _shot("act1_end_card")
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
