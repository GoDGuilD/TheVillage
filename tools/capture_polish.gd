# File: capture_polish.gd
# Description: Windowed capture script for Phase 14: in Spanish - the title screen, its options screen, the title hint with a gamepad, a villager's dialogue, an area caption with the HUD, the pause menu, the item menu, the Dark World map, Game Over and the final card; saves tmp/polish_*.png.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-21
# Last edit date: 2026-10-21
# Version: 1.0.0
# Run (NOT headless - headless cannot render):  Godot_console --path . -s tools/capture_polish.gd
extends SceneTree
## Uses throw-away save and settings paths; Joe's hurt box is off so enemies cannot spoil the shots.

const WORLD_SCENE := "res://src/world/World.tscn"
const TITLE_SCENE := "res://src/ui/TitleScreen.tscn"
const OUT := "res://tmp/"
const CAPTURE_SAVE := "user://capture_polish_save.json"
const CAPTURE_SETTINGS := "user://capture_polish_settings.cfg"

var _gs
var _audio
var _juice
var _w
var _p


func _initialize() -> void:
	await process_frame
	_gs = root.get_node("GameState")
	_audio = root.get_node("Audio")
	_juice = root.get_node("Juice")
	_gs.reset()
	_gs.drops_enabled = false
	SaveGame.path = CAPTURE_SAVE
	_audio.settings_path = CAPTURE_SETTINGS
	_audio.set_language("es")
	var title = load(TITLE_SCENE).instantiate()
	root.add_child(title)
	await _frames(90)
	await _shot("polish_title_es")
	title.menu.selected = title.ITEM_OPTIONS
	title.menu.confirm()
	await _frames(6)
	await _shot("polish_options_es")
	title.options.close()
	_juice.hints.note(InputHints.GAMEPAD, "Xbox Wireless Controller")
	await _frames(4)
	await _shot("polish_title_pad")
	_juice.hints.note(InputHints.KEYBOARD, "")
	title.queue_free()
	await _frames(2)
	for item in ["lantern", "boomerang", "bow", "bombs", "glove", "boots", "fire_rod", "moon_mirror", "grapple",
			"ice_rod", "hammer", "flippers"]:
		_gs.give_item(item)
	_gs.add_ammo("bombs", 8)
	_gs.add_ammo("arrows", 20)
	_gs.seals[0] = true
	_gs.crystals[1] = true
	_w = load(WORLD_SCENE).instantiate()
	root.add_child(_w)
	await process_frame
	_p = _w.player
	_p.hurt_box.set_deferred("monitoring", false)
	await _go("tato_house", [10, 7], Vector2i.UP)
	_w.say("tato")
	await _frames(150)
	await _shot("polish_dialogue_es")
	await _close_box()
	await _go("el_pueblo", [20, 12], Vector2i.DOWN)
	_w.hud.show_caption("EL PUEBLO")
	_w._last_area = ""
	await _go("east_lake", [6, 12], Vector2i.DOWN)
	await _frames(30)
	await _shot("polish_caption_es")
	_w.pause_menu.open()
	await _frames(4)
	await _shot("polish_pause_es")
	_w.pause_menu.close()
	_w.item_menu.open()
	await _frames(4)
	await _shot("polish_items_es")
	_w.item_menu.close()
	await _go("dw_south_fields", [16, 9], Vector2i.UP)
	for aid in _w.areas:
		if _w.is_dark(aid):
			_gs.visited[aid] = true
	_w.map_screen.open(_w.areas, _w.current_id(), _w.dungeons)
	await _frames(4)
	await _shot("polish_map_es")
	_w.map_screen.close()
	await _frames(3)
	_w.game_over.open()
	await _frames(100)
	await _shot("polish_gameover_es")
	_w.end_card.open(DialogueData.speaker("final_card"), DialogueData.pages_for("final_card", _gs))
	for i in 900:
		await process_frame
		if _w.end_card.ready_to_close:
			break
	await _shot("polish_endcard_es")
	SaveGame.delete()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CAPTURE_SETTINGS))
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


func _close_box() -> void:
	var guard := 0
	while _w.dialogue.is_open and guard < 40:
		guard += 1
		_w.dialogue.advance()
		await process_frame
		_w.dialogue.advance()
		await process_frame
	await _frames(10)


func _shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("saved ", name)
