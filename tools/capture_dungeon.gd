# File: capture_dungeon.gd
# Description: Windowed capture script for Phase 6: the shrine in the woods, the entrance room, the hub with pits and doors, a shutter, the push-block room, the map screen, the big chest's glove, the Grand Slime fight and the seal; saves tmp/dungeon_*.png.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-16
# Last edit date: 2026-10-16
# Version: 1.0.0
# Run (NOT headless - headless cannot render):  Godot_console --path . -s tools/capture_dungeon.gd
extends SceneTree
## Uses a throw-away save path; Joe's hurt box is off so enemies cannot spoil the shots.

const WORLD_SCENE := "res://src/world/World.tscn"
const OUT := "res://tmp/"
const CAPTURE_SAVE := "user://capture_dungeon_save.json"

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
	await _go("west_woods", [10, 8], Vector2i.UP)
	await _frames(10)
	await _shot("dungeon_shrine")
	await _go("d1_entrance", [11, 10], Vector2i.UP)
	await _frames(20)
	await _shot("dungeon_entrance")
	await _go("d1_hub", [11, 10], Vector2i.UP)
	await _frames(8)
	await _shot("dungeon_hub")
	await _go("d1_west", [19, 7], Vector2i.LEFT)
	await _frames(8)
	await _shot("dungeon_shutter")
	await _go("d1_northwest", [8, 10], Vector2i.UP)
	_p._input_override = Vector2.UP
	await _frames(70)
	_p._input_override = Vector2.ZERO
	await _frames(20)
	await _shot("dungeon_block_switch")
	_gs.give_dungeon_item("d1", "map")
	_gs.give_dungeon_item("d1", "compass")
	_gs.set_key_pool("d1")
	_gs.add_keys(1)
	await _go("d1_hub", [8, 6])
	_w.map_screen.open(_w.areas, _w.current_id(), _w.dungeons)
	await _frames(4)
	await _shot("dungeon_map")
	_w.map_screen.close()
	_gs.give_dungeon_item("d1", "big_key")
	await _go("d1_east", [9, 9], Vector2i.UP)
	await _tap("interact")
	_w.dialogue.advance()
	await _frames(6)
	await _shot("dungeon_glove")
	await _close()
	await _go("d1_boss", [11, 10], Vector2i.UP)
	await _frames(30)
	var boss: Node2D = null
	for e in _w.current["enemies"]:
		if is_instance_valid(e) and e.get("is_boss"):
			boss = e
	boss._on_hurt(2, boss.global_position + Vector2(0, -30), Vector2.ZERO)
	await _frames(40)
	await _shot("dungeon_boss")
	var guard := 0
	while is_instance_valid(boss) and not boss.is_dead() and guard < 30:
		guard += 1
		boss._iframes_left = 0.0
		boss._on_hurt(2, boss.global_position + Vector2(0, -30), Vector2.ZERO)
		await _frames(2)
	await _frames(int(60 * 1.6))
	await _shot("dungeon_heart_container")
	for p in get_nodes_in_group("pickup"):
		_p.global_position = p.global_position
	await _frames(6)
	await _close()
	await _frames(10)
	await _shot("dungeon_seal_appears")
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
