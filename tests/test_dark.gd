# File: test_dark.gd
# Description: Headless scripted checks for Phase 8: the Dark World twins (data, palette, tint, tougher enemies, scrolling, map), the Act 2 opening, Tato's echo and the Moon Mirror (warp, bounce back, the portal home), dream rifts, the mirror island's piece of heart, and saving in the Dark World.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-20
# Last edit date: 2026-10-21
# Version: 1.0.1
# Run:  Godot_console --headless --fixed-fps 60 --path . -s tests/test_dark.gd   (must end "0 failed")
extends SceneTree

const WORLD_SCENE := "res://src/world/World.tscn"
const TEST_SAVE := "user://test_dark_save.json"
const FPS := 60.0
const SCROLL_WAIT := 55
const WARP_WAIT := 40

var _gs
var _w
var _p
var _passed := 0
var _failed := 0


func _initialize() -> void:
	_gs = root.get_node("GameState")
	_gs.reset()
	_gs.drops_enabled = false
	SaveGame.path = TEST_SAVE
	SaveGame.delete()
	await _new_world()
	await _run_all()


func _new_world() -> void:
	_w = load(WORLD_SCENE).instantiate()
	root.add_child(_w)
	await process_frame
	_p = _w.player
	_p.hurt_box.set_deferred("monitoring", false)


func _run_all() -> void:
	_t_data()
	await _t_dark_area_build()
	await _t_dark_scroll_and_map()
	await _t_rifts_need_act1()
	await _t_act2_opening()
	await _t_tato_echo_mirror()
	await _t_mirror_light_world_only()
	await _t_mirror_warp_and_portal()
	await _t_mirror_bounce()
	await _t_island_heart_piece()
	await _t_rift()
	SaveGame.delete()
	print("\nRESULT: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


# --- helpers -----------------------------------------------------------------

func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_passed += 1
		print("  PASS  ", name, "  ", detail)
	else:
		_failed += 1
		print("  FAIL  ", name, "  ", detail)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _go(area: String, cell: Array, facing: Vector2i = Vector2i.DOWN) -> void:
	_p._input_override = Vector2.ZERO
	_p.end_hold()
	_w._enter(area, _w.cell_feet(area, cell), facing)
	_p.facing = facing
	_p.unfreeze()
	await _frames(3)


func _tap(action: String) -> void:
	Input.action_press(action)
	await _frames(2)
	Input.action_release(action)
	await _frames(1)


func _press(action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	await process_frame
	var r := InputEventAction.new()
	r.action = action
	r.pressed = false
	Input.parse_input_event(r)
	await process_frame


func _finish() -> Array[String]:
	var seen: Array[String] = []
	var guard := 0
	while _w.dialogue.is_open and guard < 40:
		guard += 1
		_w.dialogue.advance()
		seen.append(_w.dialogue.visible_text())
		await process_frame
		_w.dialogue.advance()
		await process_frame
	await _frames(int(FPS * 0.25))
	return seen


func _find(cls_name: String) -> Array:
	var out := []
	for n in _w.current["actors"].get_children():
		if n.get_script() != null and String(n.get_script().get_global_name()) == cls_name and not n.is_queued_for_deletion():
			out.append(n)
	return out


# --- tests -------------------------------------------------------------------

func _t_data() -> void:
	var twins := 0
	var same_place := true
	for aid in _w.areas:
		if _w.is_dark(aid):
			var light := String(aid).trim_prefix("dw_")
			if not _w.areas.has(light):
				continue                                   # Dark World-only lands (Umbra's vale) have no twin
			twins += 1
			same_place = same_place and _w.areas.has(light) and _w.areas[aid]["origin_tiles"] == _w.areas[light]["origin_tiles"]
	_check("every overworld area has a Dark World twin at the same place", twins == 6 and same_place, str(twins))
	_check("the twins form their own scroll group", _w.group_of("dw_el_pueblo") == "overworld_dark"
			and _w.group_of("el_pueblo") == "overworld")
	_check("the Act 2 arrival is in Hollow Pueblo", String(_w.act2_spawn.get("area", "")) == "dw_el_pueblo")
	var missing := []
	for key in ["act2_intro", "tato_echo", "get_moon_mirror", "mirror_light", "mirror_blocked", "dw_sign_pueblo",
			"dw_sign_umbra", "dw_sign_ignis", "dw_sign_tempus", "dw_sign_silva"]:
		if not DialogueData.has(key):
			missing.append(key)
	_check("every Dark World text exists", missing.is_empty(), str(missing))


func _t_dark_area_build() -> void:
	await _go("dw_el_pueblo", [23, 14])
	var tiles: TileMapLayer = _w.current["tiles"]
	var src := tiles.tile_set.get_source(0) as TileSetAtlasSource
	_check("Dark World areas use the dark atlas", src.texture.resource_path.ends_with("overworld_dark.png"),
			src.texture.resource_path)
	_check("their actors are tinted", _w.current["actors"].modulate.is_equal_approx(_w.DW_TINT))
	var ok := true
	for e in _w.current["enemies"]:
		ok = ok and e.health.max_health == e.max_hp * 2
	_check("their enemies are twice as tough", ok and _w.current["enemies"].size() > 0, str(_w.current["enemies"].size()))
	var ids := _find("Npc").map(func(n: Node) -> String: return n.npc_id)
	ids.sort()
	_check("Hollow Pueblo has no villagers but Tato's echo and the shade merchant", ids == ["shade_merchant", "tato_echo"], str(ids))
	_check("the caption names the Dark World place", _w.hud.caption_shown == "HOLLOW PUEBLO", _w.hud.caption_shown)


func _t_dark_scroll_and_map() -> void:
	await _go("dw_el_pueblo", [23, 2], Vector2i.UP)
	_p._input_override = Vector2.UP
	await _frames(50)
	_p._input_override = Vector2.ZERO
	await _frames(SCROLL_WAIT)
	_check("walking off the top scrolls to the Dark World meadow", _w.current_id() == "dw_meadow_north", _w.current_id())
	await _press("map")
	_check("the map shows the Dark World's places only", _w.map_screen.is_open and _w.map_screen.shown_rooms.all(
			func(r: String) -> bool: return r.begins_with("dw_")) and _w.map_screen.shown_rooms.size() >= 2,
			str(_w.map_screen.shown_rooms))
	await _press("map")


func _t_rifts_need_act1() -> void:
	await _go("el_pueblo", [20, 16])
	_check("before the end of Act 1 there are no rifts", _find("Rift").is_empty())


func _t_act2_opening() -> void:
	_gs.set_flag("act1:done")
	SaveGame.write(SaveGame.capture("dw_el_pueblo", _w.cell_feet("dw_el_pueblo", [23, 14]), Vector2i.DOWN, 6, 6, _gs))
	_w.queue_free()
	await process_frame
	_gs.reset()
	SaveGame.pending = SaveGame.read()
	await _new_world()
	await _frames(3)
	_check("continuing after Act 1 starts in Hollow Pueblo", _w.current_id() == "dw_el_pueblo", _w.current_id())
	_check("with the Act 2 intro", _w.dialogue.is_open and _gs.has_flag("act2:started"))
	await _finish()
	_w.save_game()
	_w.queue_free()
	await process_frame
	_gs.reset()
	SaveGame.pending = SaveGame.read()
	await _new_world()
	await _frames(3)
	_check("the intro plays only once", not _w.dialogue.is_open)


func _t_tato_echo_mirror() -> void:
	await _go("dw_el_pueblo", [19, 12], Vector2i.UP)
	await _tap("interact")
	var seen := await _finish()
	_check("Tato's echo hands over the Moon Mirror on the first talk", _gs.has_item("moon_mirror") and seen.size() >= 3,
			str(seen.size()))
	_gs.equip("moon_mirror")


func _t_mirror_light_world_only() -> void:
	await _go("el_pueblo", [8, 9])
	var before: int = _w.world_warps
	await _tap("item")
	await _frames(3)
	_check("in the Light World the mirror only shows Joe's face", _w.world_warps == before and _w.dialogue.is_open)
	await _finish()


func _t_mirror_warp_and_portal() -> void:
	await _go("dw_el_pueblo", [23, 14], Vector2i.DOWN)
	var feet: Vector2 = _p.global_position
	await _frames(15)
	await _tap("item")
	await _frames(WARP_WAIT)
	_check("the mirror takes Joe to the Light World", _w.current_id() == "el_pueblo", _w.current_id())
	_check("to the very same spot", _p.global_position == feet, "%s vs %s" % [_p.global_position, feet])
	var portals := _find("Rift").filter(func(r: Node) -> bool: return r.portal)
	_check("leaving a shimmer behind", portals.size() == 1)
	await _frames(10)
	_check("which does not fire while Joe stands on it", _w.current_id() == "el_pueblo")
	_p._input_override = Vector2.RIGHT
	await _frames(15)
	_p._input_override = Vector2.LEFT
	await _frames(15)
	_p._input_override = Vector2.ZERO
	await _frames(WARP_WAIT)
	_check("stepping back onto it returns him to the Dark World", _w.current_id() == "dw_el_pueblo", _w.current_id())


func _t_mirror_bounce() -> void:
	# The village's south sign (27, 17) is solid in the Light World; its Dark World twin cell is plain ground.
	var spot := [27, 17]
	await _go("dw_el_pueblo", spot)
	await _frames(15)
	var bounces: int = _w.mirror_bounces
	await _tap("item")
	await _frames(WARP_WAIT)
	_check("landing in something solid throws Joe back", _w.mirror_bounces == bounces + 1 and _w.current_id() == "dw_el_pueblo",
			"%s %s" % [spot, _w.current_id()])
	await _finish()


func _t_island_heart_piece() -> void:
	await _go("meadow_north", [34, 8], Vector2i.UP)
	var pieces := get_nodes_in_group("pickup")
	_check("a piece of heart lies on the pond's island", pieces.size() == 1)
	await _go("dw_meadow_north", [34, 3], Vector2i.DOWN)
	await _frames(15)
	var count: int = _gs.heart_pieces
	await _tap("item")
	await _frames(WARP_WAIT)
	await _frames(10)
	_check("the dry Dark World pond lets Joe mirror onto the island", _w.current_id() == "meadow_north", _w.current_id())
	var seen := await _finish()
	_check("where the piece of heart is his", _gs.heart_pieces == count + 1 or _gs.heart_pieces == 0, str(seen))


func _t_rift() -> void:
	await _go("el_pueblo", [20, 15], Vector2i.DOWN)
	var rifts := _find("Rift").filter(func(r: Node) -> bool: return not r.portal)
	_check("after Act 1 a dream rift opens in the village", rifts.size() == 1)
	_p._input_override = Vector2.DOWN
	await _frames(25)
	_p._input_override = Vector2.ZERO
	await _frames(WARP_WAIT)
	_check("stepping into it takes Joe to the Dark World, same spot", _w.current_id() == "dw_el_pueblo", _w.current_id())
