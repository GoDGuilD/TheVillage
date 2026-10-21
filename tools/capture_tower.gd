# File: capture_tower.gd
# Description: Windowed capture script for Phase 13: the crystal gate shut (three sockets lit) and open, the Dark World map, the tower's Umbra, Ignis, Tempus and Silva floors, Caver's opening words, Caver casting, knocked down, winged with his bats, the dungeon map of the tower, and the final card; saves tmp/tower_*.png.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-20
# Last edit date: 2026-10-20
# Version: 1.0.0
# Run (NOT headless - headless cannot render):  Godot_console --path . -s tools/capture_tower.gd
extends SceneTree
## Uses a throw-away save path; Joe's hurt box is off so enemies cannot spoil the shots.

const WORLD_SCENE := "res://src/world/World.tscn"
const OUT := "res://tmp/"
const CAPTURE_SAVE := "user://capture_tower_save.json"

var _gs
var _w
var _p


func _initialize() -> void:
	_gs = root.get_node("GameState")
	_gs.reset()
	_gs.drops_enabled = false
	_gs.set_flag("act1:done")
	_gs.set_flag("act2:started")
	for i in _gs.CRYSTAL_COUNT:
		_gs.crystals[i] = i != 2
	for item in ["lantern", "grapple", "ice_rod", "hammer", "flippers", "fire_rod"]:
		_gs.give_item(item)
	SaveGame.path = CAPTURE_SAVE
	_w = load(WORLD_SCENE).instantiate()
	root.add_child(_w)
	await process_frame
	_p = _w.player
	_p.hurt_box.set_deferred("monitoring", false)
	await _go("dw_south_fields", [15, 9], Vector2i.UP)
	await _frames(200)                              # the area caption has faded off the gate
	await _shot("tower_gate_shut")
	_gs.crystals[2] = true
	await _go("dw_south_fields", [15, 7], Vector2i.UP)
	_w._on_talk_requested(_find("SealGate")[0])
	await _frames(30)
	await _shot("tower_gate_opening")
	await _close_box()
	await _go("dw_south_fields", [16, 9], Vector2i.UP)
	await _frames(10)
	await _shot("tower_gate_open")
	for aid in _w.areas:
		if _w.is_dark(aid):
			_gs.visited[aid] = true
	_w.map_screen.open(_w.areas, _w.current_id(), _w.dungeons)
	await _frames(6)
	await _shot("tower_dark_world_map")
	_w.map_screen.close()
	await _frames(3)
	await _go("d8_umbra", [8, 8], Vector2i.UP)
	await _frames(10)
	await _shot("tower_umbra")
	await _go("d8_ignis", [11, 9], Vector2i.UP)
	_gs.equip("ice_rod")
	_gs.add_magic(_gs.MAX_MAGIC)
	await _tap("item")
	await _frames(30)
	await _shot("tower_ignis")
	await _go("d8_tempus", [11, 5], Vector2i.UP)
	await _frames(20)
	await _shot("tower_tempus")
	await _go("d8_silva", [19, 7], Vector2i.LEFT)
	_p._input_override = Vector2.LEFT
	await _frames(70)
	_p._input_override = Vector2.ZERO
	await _frames(10)
	await _shot("tower_silva")
	_gs.give_dungeon_item("d8", "map")
	_gs.give_dungeon_item("d8", "compass")
	_w.map_screen.open(_w.areas, _w.current_id(), _w.dungeons)
	await _frames(6)
	await _shot("tower_map")
	_w.map_screen.close()
	await _frames(3)
	await _go("d8_boss", [11, 10], Vector2i.UP)
	await _frames(40)
	await _shot("tower_intro")
	await _close_box()
	var caver := _boss()
	for i in 200:
		await _frames(1)
		if not get_nodes_in_group("orb").is_empty():
			break
	await _frames(14)
	await _shot("tower_caver_cast")
	caver.casts = caver.VOLLEY_EVERY - 1
	caver.cast()
	await _frames(18)
	await _shot("tower_caver_volley")
	for o in get_nodes_in_group("orb"):
		o.bat_back()
	for i in 120:
		await _frames(1)
		if caver.is_dazed():
			break
	await _frames(20)
	await _shot("tower_caver_dazed")
	caver.health.current_health = caver.health.max_health / 2
	caver.phase = "fade_in"
	caver._timer = 0.05
	await _frames(40)
	caver.call_bat()
	await _frames(20)
	await _shot("tower_caver_rage")
	while is_instance_valid(caver) and not caver.is_dead():
		_hit(caver, 1, "orb")
		if not caver.is_dead():
			_hit(caver, 2)
		await _frames(2)
	await _frames(40)
	await _shot("tower_caver_sinks")
	for i in 200:
		await _frames(1)
		if _w.dialogue.is_open:
			break
	await _frames(40)
	await _shot("tower_last_words")
	await _close_box()
	for i in 900:
		await process_frame
		if _w.end_card.ready_to_close:
			break
	await _shot("tower_final_card")
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


func _tap(action: String) -> void:
	Input.action_press(action)
	await _frames(2)
	Input.action_release(action)
	await _frames(1)


func _close_box() -> void:
	var guard := 0
	while _w.dialogue.is_open and guard < 40:
		guard += 1
		_w.dialogue.advance()
		await process_frame
		_w.dialogue.advance()
		await process_frame
	await _frames(10)


func _find(cls_name: String) -> Array:
	var out := []
	for n in _w.current["actors"].get_children():
		if n.get_script() != null and String(n.get_script().get_global_name()) == cls_name:
			out.append(n)
	return out


func _boss() -> Node2D:
	for e in _w.current["enemies"]:
		if is_instance_valid(e) and e.get("is_boss"):
			return e
	return null


func _hit(e: Node2D, damage: int, element: String = "") -> void:
	var hb := HitBox.new()
	hb.element = element
	e.hurt_box.last_hit = hb
	e._iframes_left = 0.0
	e._on_hurt(damage, e.global_position + Vector2(0, -30), Vector2.ZERO)
	hb.free()


func _shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("saved ", name)
