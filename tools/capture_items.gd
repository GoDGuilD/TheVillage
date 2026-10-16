# File: capture_items.gd
# Description: Windowed capture script for Phase 5: the lantern item-get, lit torches with the revealed chest, the boomerang and an arrow in flight, a bomb blast, Boni's counter with wares, the key-block nook and the item menu; saves tmp/items_*.png.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
# Run (NOT headless - headless cannot render):  Godot_console --path . -s tools/capture_items.gd
extends SceneTree
## Uses a throw-away save path; Joe's hurt box is off so enemies cannot spoil the shots.

const WORLD_SCENE := "res://src/world/World.tscn"
const OUT := "res://tmp/"
const CAPTURE_SAVE := "user://capture_items_save.json"

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
	# The lantern chest: Joe holds it up.
	await _go("joe_house", [10, 3], Vector2i.UP)
	await _tap("interact")
	_w.dialogue.advance()
	await _frames(6)
	await _shot("items_get_lantern")
	await _close()
	# Both meadow torches lit, the chest revealed.
	await _go("meadow_north", [28, 5], Vector2i.UP)
	await _tap("item")
	await _frames(20)
	_p.global_position = _w.cell_feet("meadow_north", [39, 5])
	_p.facing = Vector2i.UP
	await _tap("item")
	await _frames(30)
	_p.global_position = _w.cell_feet("meadow_north", [33, 9])
	await _frames(6)
	await _shot("items_torches")
	# Weapons for the rest of the shots.
	for item in ["boomerang", "bow", "bombs"]:
		_gs.give_item(item)
	_gs.add_ammo("arrows", 20)
	_gs.add_ammo("bombs", 8)
	_gs.add_gems(123)
	_gs.equip("boomerang")
	await _go("el_pueblo", [8, 13], Vector2i.RIGHT)
	await _tap("item")
	await _frames(14)
	await _shot("items_boomerang")
	await _frames(70)
	_gs.equip("bow")
	_p.facing = Vector2i.RIGHT
	await _tap("item")
	await _frames(8)
	await _shot("items_arrow")
	await _frames(40)
	_gs.equip("bombs")
	_p.facing = Vector2i.RIGHT
	await _tap("item")
	_p.global_position = _w.cell_feet("el_pueblo", [5, 13])
	await _frames(int(60 * 1.0))
	await _shot("items_bomb_fuse")
	await _frames(int(60 * 0.62))
	await _shot("items_explosion")
	await _frames(30)
	await _go("boni_shop", [7, 6], Vector2i.UP)
	await _frames(6)
	await _shot("items_shop")
	await _go("south_road", [40, 9], Vector2i.RIGHT)
	await _frames(6)
	await _shot("items_key_nook")
	_w.item_menu.open()
	await _frames(4)
	await _shot("items_menu")
	_w.item_menu.close()
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
