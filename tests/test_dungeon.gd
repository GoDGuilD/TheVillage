# File: test_dungeon.gd
# Description: Headless scripted checks for Phase 6: the Moss Shrine's data, the shrine entrance and stairs, room-to-room scrolls, pits, per-dungeon keys, locked/big/shutter doors, room clearing, floor switches and the push block, map/compass and the map screen, the big chest and the power glove, the Grand Slime and its reward, and saving dungeon progress.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-16
# Last edit date: 2026-10-16
# Version: 1.0.0
# Run:  Godot_console --headless --fixed-fps 60 --path . -s tests/test_dungeon.gd   (must end "0 failed")
extends SceneTree

const WORLD_SCENE := "res://src/world/World.tscn"
const TEST_SAVE := "user://test_dungeon_save.json"
const FPS := 60.0
const SCROLL_WAIT := 55
const WARP_WAIT := 45

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
	_w = load(WORLD_SCENE).instantiate()
	root.add_child(_w)
	await process_frame
	_p = _w.player
	_p.hurt_box.set_deferred("monitoring", false)
	await _run_all()


func _run_all() -> void:
	_t_data()
	await _t_entrance_and_stairs()
	await _t_room_scroll()
	await _t_pit()
	await _t_locked_door_needs_key()
	await _t_clear_room_shutter()
	await _t_push_block_switch()
	await _t_locked_door_opens()
	await _t_switch_shutter()
	await _t_map_and_compass()
	await _t_big_key_chest_door()
	await _t_boss()
	await _t_glove_rocks()
	await _t_save_dungeon_progress()
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


# A real key press through the input pipeline (menus read _unhandled_input).
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


func _walk(dir: Vector2, frames: int) -> void:
	_p._input_override = dir
	await _frames(frames)
	_p._input_override = Vector2.ZERO
	await _frames(2)


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


func _door(id: String) -> Node:
	for d in _find("Door"):
		if d.door_id == id:
			return d
	return null


func _kill_all_enemies() -> void:
	for e in _w.current["enemies"]:
		if is_instance_valid(e) and not e.is_dead():
			e._on_hurt(99, e.global_position + Vector2(0, -20), Vector2.ZERO)
	await _frames(3)


# --- tests -------------------------------------------------------------------

func _t_data() -> void:
	var rooms := []
	for aid in _w.areas:
		if _w.dungeon_of(aid) == "d1":
			rooms.append(aid)
	_check("the Moss Shrine has eight rooms", rooms.size() == 8, str(rooms.size()))
	var info: Dictionary = _w.dungeons.get("d1", {})
	_check("the dungeon table names its entrance, boss room and seal", info.get("entrance") == "d1_entrance"
			and info.get("boss_room") == "d1_boss" and int(info.get("seal", -1)) == 0)
	var missing := []
	for key in ["get_map", "get_compass", "get_big_key", "get_glove", "get_seal", "locked_door", "big_door",
			"big_chest_locked", "sign_shrine"]:
		if not DialogueData.has(key):
			missing.append(key)
	_check("every dungeon text exists", missing.is_empty(), str(missing))


func _t_entrance_and_stairs() -> void:
	await _go("west_woods", [10, 7], Vector2i.UP)
	await _walk(Vector2.UP, 12)
	await _frames(WARP_WAIT)
	_check("the shrine door leads into the entrance room", _w.current_id() == "d1_entrance", _w.current_id())
	_check("the caption names the shrine", _w.hud.caption_shown == "MOSS SHRINE", _w.hud.caption_shown)
	_check("keys now count for this dungeon, and the HUD shows them even at zero",
			_gs.key_pool == "d1" and _w.hud._key_icon.visible)
	await _walk(Vector2.DOWN, 20)
	await _frames(WARP_WAIT)
	_check("the stairs lead back out to the woods", _w.current_id() == "west_woods", _w.current_id())
	_check("outside, the keys are the overworld's again", _gs.key_pool == "" and not _w.hud._key_icon.visible)


func _t_room_scroll() -> void:
	await _go("d1_entrance", [11, 4], Vector2i.UP)
	_w.hud.caption_shown = ""
	var before: int = _w.transitions
	await _walk(Vector2.UP, 70)
	await _frames(SCROLL_WAIT)
	_check("walking through the north doorway scrolls into the hub", _w.current_id() == "d1_hub" and _w.transitions > before,
			_w.current_id())
	var local: Vector2 = _p.global_position - _w.current["rect"].position
	_check("Joe ends up past the thick wall", local.y < _w.current["rect"].size.y - 32.0, str(local))
	_check("room to room inside the dungeon shows no caption", _w.hud.caption_shown == "")
	_check("visited rooms are remembered", _gs.visited.has("d1_entrance") and _gs.visited.has("d1_hub"))


func _t_pit() -> void:
	await _go("d1_hub", [7, 3], Vector2i.LEFT)
	_p._input_override = Vector2.ZERO
	var hp: int = _p.health.current_health
	var entry: Vector2 = _w.entry_point
	await _walk(Vector2.LEFT, 10)
	_check("walking onto a pit drops Joe in", _p.is_falling() or _w.falls == 1, _p.fsm.current_state)
	await _frames(int(FPS * 0.8))
	_check("a fall costs one heart", _w.falls == 1 and _p.health.current_health == hp - 2, "%d -> %d" % [hp, _p.health.current_health])
	_check("and puts him back where he entered the room", _p.global_position == entry and _p.fsm.current_state == "idle")
	_p.health.heal(99)


func _t_locked_door_needs_key() -> void:
	await _go("d1_hub", [21, 6], Vector2i.RIGHT)
	await _tap("interact")
	var door := _door("d1_hub_east")
	_check("the east door is locked", door != null and not door.is_open and _w.dialogue.is_open)
	await _finish()
	_gs.set_key_pool("")
	_gs.add_keys(1)
	_gs.set_key_pool("d1")
	_check("an overworld key does not count here", _gs.keys == 0)
	_gs.set_key_pool("")
	_gs.add_keys(-1)
	_gs.set_key_pool("d1")


func _t_clear_room_shutter() -> void:
	await _go("d1_west", [20, 6], Vector2i.LEFT)
	var shutter := _door("d1_west_north")
	_check("the west room's north shutter is shut while enemies live", shutter != null and not shutter.is_open)
	await _kill_all_enemies()
	await _frames(5)
	_check("clearing the room opens it", shutter.is_open and _gs.has_flag("cleared:d1_west"))
	await _go("d1_west", [4, 4], Vector2i.UP)
	await _tap("interact")
	await _finish()
	_check("the west chest holds the map", _gs.has_dungeon_item("d1", "map"))
	await _go("d1_hub", [8, 6])
	await _go("d1_west", [20, 6], Vector2i.LEFT)
	_check("back later, the shutter stays open though enemies return", _door("d1_west_north").is_open)


func _t_push_block_switch() -> void:
	await _go("d1_northwest", [8, 10], Vector2i.UP)
	var chest: Array = _find("Chest")
	_check("the northwest chest is hidden", chest.size() == 1 and chest[0].concealed)
	var sw: Array = _find("FloorSwitch")
	_p.global_position = _w.cell_feet("d1_northwest", [8, 5])
	await _frames(5)
	_check("Joe alone cannot press the heavy switch", not sw[0].pressed)
	await _go("d1_northwest", [8, 10], Vector2i.UP)
	var block: Array = _find("PushBlock")
	sw = _find("FloorSwitch")                         # the room was rebuilt: fetch its nodes again
	chest = _find("Chest")
	await _walk(Vector2.UP, int(FPS * 2.6))
	_check("pushing moves the block a tile at a time", block[0].pushes >= 3, str(block[0].pushes))
	await _frames(10)
	_check("the block on the switch presses it", sw[0].pressed and _gs.has_flag("switch:d1_northwest"))
	_check("which reveals the chest", not chest[0].concealed and chest[0].visible)
	await _go("d1_northwest", [15, 5], Vector2i.UP)
	await _tap("interact")
	await _finish()
	_check("it holds this dungeon's small key", _gs.keys == 1 and _gs.key_pool == "d1")


func _t_locked_door_opens() -> void:
	await _go("d1_hub", [21, 6], Vector2i.RIGHT)
	await _tap("interact")
	await _frames(3)
	var door := _door("d1_hub_east")
	_check("the key opens the east door", door.is_open and _gs.keys == 0 and _gs.has_flag("door:d1_hub_east"))
	await _walk(Vector2.RIGHT, 60)
	await _frames(SCROLL_WAIT)
	_check("and Joe walks through into the east room", _w.current_id() == "d1_east", _w.current_id())
	_check("the same door is open from that side too", _door("d1_hub_east").is_open)


func _t_switch_shutter() -> void:
	await _go("d1_east", [17, 6], Vector2i.UP)
	var shutter := _door("d1_east_north")
	_check("the east room's north shutter starts shut", shutter != null and not shutter.is_open)
	await _walk(Vector2.UP, 30)
	await _frames(5)
	_check("stepping on the switch across the bridge opens it", shutter.is_open and _gs.has_flag("switch:d1_east"))
	await _go("d1_east", [4, 4], Vector2i.UP)
	await _tap("interact")
	await _finish()
	_check("the east chest holds the compass", _gs.has_dungeon_item("d1", "compass"))


func _t_map_and_compass() -> void:
	await _go("d1_hub", [8, 6])
	await _press("map")
	_check("Tab opens the map and pauses", _w.map_screen.is_open and paused)
	_check("with the dungeon map every room is drawn", _w.map_screen.shown_rooms.size() == 8, str(_w.map_screen.shown_rooms.size()))
	_check("the compass marks the boss room", _w.map_screen.boss_marked == "d1_boss")
	_check("Joe's room is marked", _w.map_screen.here == "d1_hub")
	await _press("map")
	_check("Tab again closes it", not _w.map_screen.is_open and not paused)


func _t_big_key_chest_door() -> void:
	await _go("d1_east", [9, 9], Vector2i.UP)
	await _tap("interact")
	var seen := await _finish()
	_check("the big chest will not open without the big key", not _gs.has_item("glove") and seen.size() > 0, str(seen))
	await _go("d1_northeast", [12, 4], Vector2i.UP)
	await _tap("interact")
	await _finish()
	_check("the northeast chest holds the big key", _gs.has_dungeon_item("d1", "big_key"))
	await _go("d1_east", [9, 9], Vector2i.UP)
	await _tap("interact")
	await _finish()
	_check("now the big chest gives the power glove", _gs.has_item("glove") and _gs.equipped != "glove")
	await _go("d1_hub", [11, 2], Vector2i.UP)
	await _tap("interact")
	await _frames(3)
	_check("the big key opens the big door", _door("d1_hub_north").is_open and _gs.has_flag("door:d1_hub_north"))


func _t_boss() -> void:
	await _go("d1_ante", [11, 3], Vector2i.UP)
	await _walk(Vector2.UP, 60)
	await _frames(SCROLL_WAIT)
	_check("the antechamber leads up into the boss room", _w.current_id() == "d1_boss", _w.current_id())
	var boss_door := _door("d1_boss_door")
	_check("the boss door shuts behind Joe", boss_door != null and not boss_door.is_open)
	var boss: Node2D = null
	for e in _w.current["enemies"]:
		if is_instance_valid(e) and e.get("is_boss"):
			boss = e
	_check("the Grand Slime waits inside", boss != null)
	boss.freeze(60.0)
	boss._on_hurt(2, boss.global_position + Vector2(0, -30), Vector2.ZERO)
	await _frames(3)
	_check("a hit buds off a small slime", boss.minions.size() == 1)
	_check("the boomerang cannot stun it", boss.stun_immune)
	var guard := 0
	while is_instance_valid(boss) and not boss.is_dead() and guard < 30:
		guard += 1
		boss._iframes_left = 0.0
		boss._on_hurt(2, boss.global_position + Vector2(0, -30), Vector2.ZERO)
		await _frames(2)
	_check("the Grand Slime falls", not is_instance_valid(boss) or boss.is_dead())
	await _frames(3)
	_check("its fall is remembered and the door opens", _gs.has_flag("boss:d1") and boss_door.is_open)
	await _frames(int(FPS * 1.5))
	var pickups := get_nodes_in_group("pickup")
	_check("a heart container appears", pickups.size() == 1 and pickups[0].kind == "heart_container")
	var max_before: int = _p.health.max_health
	_p.global_position = pickups[0].global_position
	await _frames(4)
	await _finish()
	_check("taking it adds a heart", _p.health.max_health == max_before + 2)
	await _frames(3)
	pickups = get_nodes_in_group("pickup")
	_check("then the family seal appears", pickups.size() == 1 and pickups[0].kind == "seal")
	_p.global_position = pickups[0].global_position
	await _frames(4)
	var seen := await _finish()
	_check("Joe takes the first family seal", _gs.seals[0], str(seen))
	await _frames(WARP_WAIT)
	_check("and is sent back out to the woods", _w.current_id() == "west_woods", _w.current_id())
	await _go("d1_boss", [11, 9], Vector2i.UP)
	var again := 0
	for e in _w.current["enemies"]:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			again += 1
	_check("the boss room stays empty afterwards", again == 0 and get_nodes_in_group("pickup").is_empty())


func _t_glove_rocks() -> void:
	await _go("east_lake", [21, 20], Vector2i.DOWN)
	var rocks := _find("HeavyRock")
	_check("heavy rocks guard the lake's heart piece", rocks.size() == 2)
	await _tap("interact")
	await _frames(15)
	_check("with the glove Joe lifts one", _p.carrying == "rock", _p.carrying)
	_p.facing = Vector2i.UP
	await _tap("interact")
	await _frames(40)
	_check("and throws it", _p.carrying == "" and _find("HeavyRock").size() == 1)


func _t_save_dungeon_progress() -> void:
	await _go("el_pueblo", [8, 9])
	_check("save_game succeeds", _w.save_game())
	_w.queue_free()
	await process_frame
	_gs.reset()
	SaveGame.pending = SaveGame.read()
	_w = load(WORLD_SCENE).instantiate()
	root.add_child(_w)
	await process_frame
	_p = _w.player
	_p.hurt_box.set_deferred("monitoring", false)
	_check("dungeon items, the seal and the glove come back", _gs.has_dungeon_item("d1", "big_key") and _gs.seals[0]
			and _gs.has_item("glove"))
	_check("visited rooms come back", _gs.visited.has("d1_boss"))
	await _go("d1_hub", [8, 6])
	_check("opened doors stay open", _door("d1_hub_east").is_open and _door("d1_hub_north").is_open)
