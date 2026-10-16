# File: capture_ui.gd
# Description: Windowed capture script for Phase 4 screens: title, HUD with area caption, Tato's dialogue, a sign, Boni across her counter, the pause menu, the item menu and Game Over; saves tmp/ui_*.png.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
# Run (NOT headless - headless cannot render):  Godot_console --path . -s tools/capture_ui.gd
extends SceneTree
## Uses a throw-away save path so the player's real save is never touched; Joe's hurt box is off.

const WORLD_SCENE := "res://src/world/World.tscn"
const TITLE_SCENE := "res://src/ui/TitleScreen.tscn"
const OUT := "res://tmp/"
const CAPTURE_SAVE := "user://capture_village_save.json"

var _w
var _p


func _initialize() -> void:
	var gs := root.get_node("GameState")
	gs.reset()
	gs.drops_enabled = false
	SaveGame.path = CAPTURE_SAVE
	SaveGame.write({"version": SaveGame.VERSION, "area": "el_pueblo"})   # so CONTINUE shows enabled
	var t = load(TITLE_SCENE).instantiate()
	root.add_child(t)
	await _frames(20)
	await _shot("ui_title")
	t.queue_free()
	await process_frame
	_w = load(WORLD_SCENE).instantiate()
	root.add_child(_w)
	await process_frame
	_p = _w.player
	_p.hurt_box.set_deferred("monitoring", false)
	gs.add_gems(57)
	gs.use_magic(10)
	_p.health.take_damage(1)
	await _go("el_pueblo", [8, 9])
	await _frames(20)
	await _shot("ui_hud_caption")
	# Tato's first words, fully typed.
	await _go("tato_house", [10, 5], Vector2i.UP)
	await _talk()
	await _shot("ui_dialogue_tato")
	await _close_all()
	# The crossroads sign.
	await _go("el_pueblo", [20, 11], Vector2i.UP)
	await _talk()
	await _shot("ui_sign")
	await _close_all()
	# Boni behind her counter; the box goes to the top when Joe is low on screen - here it stays at the bottom.
	await _go("boni_shop", [7, 5], Vector2i.UP)
	await _talk()
	await _shot("ui_boni")
	await _close_all()
	await _go("el_pueblo", [8, 9])
	_w.pause_menu.open()
	await _frames(4)
	await _shot("ui_pause")
	_w.pause_menu.close()
	gs.seals[0] = true
	_w.item_menu.open()
	await _frames(4)
	await _shot("ui_items")
	_w.item_menu.close()
	_p._on_hurt(99, _p.global_position + Vector2(0, -20), Vector2.ZERO)
	await _frames(int(60 * 3.2))
	await _shot("ui_game_over")
	SaveGame.delete()
	quit(0)


func _go(area: String, cell: Array, facing: Vector2i = Vector2i.DOWN) -> void:
	_p._input_override = Vector2.ZERO
	_w._enter(area, _w.cell_feet(area, cell), facing)
	_p.unfreeze()
	await _frames(6)


func _talk() -> void:
	Input.action_press("interact")
	await _frames(2)
	Input.action_release("interact")
	await _frames(2)
	_w.dialogue.advance()                        # show the whole first box
	await _frames(3)


func _close_all() -> void:
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
