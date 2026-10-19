# File: test_world.gd
# Description: Headless scripted checks for Phase 3 (and the Phase 4 Game Over): area data, house doors and exit mats, ALttP screen scrolls in all directions, camera clamping, ledge hops, water, enemy respawn, death and the Game Over continue.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-20
# Version: 1.1.4
# Run:  Godot_console --headless --fixed-fps 60 --path . -s tests/test_world.gd   (must end "0 failed")
extends SceneTree

const WORLD_SCENE := "res://src/world/World.tscn"
const FPS := 60.0
const TILE := 16.0
const VIEW := Vector2(384, 216)
const SCROLL_WAIT := 50                   # frames: the 0.6 s slide plus margin
const WARP_WAIT := 40                     # frames: fade out + fade in plus margin

var _w
var _p
var _passed := 0
var _failed := 0


func _initialize() -> void:
	var gs := root.get_node("GameState")
	gs.reset()
	gs.drops_enabled = false
	_w = load(WORLD_SCENE).instantiate()
	root.add_child(_w)
	await process_frame
	_p = _w.player
	await _run_all()


func _run_all() -> void:
	await _t_data()
	await _t_starts_at_home()
	await _t_exit_mat_and_door()
	await _t_scroll_north()
	await _t_scroll_other_sides()
	await _t_camera_clamps()
	await _t_ledge_hop()
	await _t_water_is_solid()
	await _t_enemies_respawn()
	await _t_death_respawn_at_entry()
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


# Jump straight into `area` with Joe's feet on `cell` (no transition), facing `facing`.
func _go(area: String, cell: Array, facing: Vector2i = Vector2i.DOWN) -> void:
	_p._input_override = Vector2.ZERO
	_w._enter(area, _w.cell_feet(area, cell), facing)
	_p.unfreeze()
	await _frames(3)


func _hold(dir: Vector2, frames: int) -> void:
	_p._input_override = dir
	await _frames(frames)
	_p._input_override = Vector2.ZERO


func _cell_of(area: String) -> Vector2i:
	return Vector2i(((_p.global_position - _w.origin_of(area)) / TILE).floor())


# --- tests -------------------------------------------------------------------

func _t_data() -> void:
	_check("39 areas load (6 + 6 Dark World overworld, 4 houses, 23 dungeon rooms)", _w.areas.size() == 39, str(_w.areas.size()))
	var doors := 0
	var ok := true
	for aid in _w.areas:
		for d in _w.areas[aid]["doors"]:
			doors += 1
			ok = ok and _w.areas.has(String(d["to"]))
	_check("nine doors (houses, three dungeons, the keep's gateway), all leading somewhere", doors == 9 and ok, str(doors))
	_check("start area is Joe's house", _w.start_area == "joe_house")


func _t_starts_at_home() -> void:
	_check("the game starts inside Joe's house", _w.current_id() == "joe_house", _w.current_id())
	var rect: Rect2 = _w.current["rect"]
	_check("a small room is centred by the camera", _w.camera.global_position == rect.get_center().round(),
			"%s vs %s" % [_w.camera.global_position, rect.get_center()])


func _t_exit_mat_and_door() -> void:
	await _go("joe_house", [7, 7])
	var t0: int = _w.transitions
	await _hold(Vector2.DOWN, 30)
	await _frames(WARP_WAIT)
	_check("the exit mat leads outside", _w.current_id() == "el_pueblo", _w.current_id())
	_check("Joe stands below his front door", _cell_of("el_pueblo") == Vector2i(8, 7), str(_cell_of("el_pueblo")))
	_check("one warp counted", _w.transitions == t0 + 1)
	_check("Joe can move again after the fade", not _w.transitioning and _p._frozen_left <= 0.0)
	await _hold(Vector2.UP, 20)
	await _frames(WARP_WAIT)
	_check("walking into the door goes back in", _w.current_id() == "joe_house", _w.current_id())
	_check("door sound", root.get_node("Audio").played_recently("door", 30))


func _t_scroll_north() -> void:
	await _go("el_pueblo", [23, 2], Vector2i.UP)
	var old_actors = _w.current["actors"]
	_p._input_override = Vector2.UP
	var saw_freeze := false
	for i in 40:
		await _frames(1)
		if _w.transitioning:
			saw_freeze = saw_freeze or _p._frozen_left > 0.0
	_p._input_override = Vector2.ZERO
	await _frames(SCROLL_WAIT)
	_check("walking off the top scrolls to the meadow", _w.current_id() == "meadow_north", _w.current_id())
	_check("Joe is frozen during the slide", saw_freeze)
	_check("Joe ends up inside the meadow", _w.current["rect"].has_point(_p.global_position), str(_p.global_position))
	_check("the village was unloaded", not is_instance_valid(old_actors))
	_check("the camera stays inside the meadow", _w.current["rect"].grow(0.5).encloses(Rect2(_w.camera.global_position - VIEW / 2.0, VIEW)))


func _t_scroll_other_sides() -> void:
	var cases := [["el_pueblo", [2, 13], Vector2.LEFT, "west_woods"], ["el_pueblo", [45, 13], Vector2.RIGHT, "east_lake"],
			["el_pueblo", [23, 25], Vector2.DOWN, "south_road"], ["meadow_north", [23, 11], Vector2.DOWN, "el_pueblo"]]
	for c in cases:
		await _go(c[0], c[1])
		await _hold(c[2], 45)
		await _frames(SCROLL_WAIT)
		_check("%s -> %s" % [c[0], c[3]], _w.current_id() == c[3], _w.current_id())


func _t_camera_clamps() -> void:
	await _go("el_pueblo", [3, 3])
	var rect: Rect2 = _w.current["rect"]
	var cam: Vector2 = _w.camera.global_position
	_check("camera clamps at the area's top-left", cam == rect.position + VIEW / 2.0, str(cam - rect.position))
	await _go("el_pueblo", [23, 13])
	cam = _w.camera.global_position
	_check("camera follows Joe in the middle", absf(cam.x - (_p.global_position.x)) <= 1.0, str(cam))


func _t_ledge_hop() -> void:
	# South road: the road meets a ledge on row 6 (columns 16-27); the landing is row 7.
	await _go("south_road", [23, 4], Vector2i.DOWN)
	_p._input_override = Vector2.DOWN
	var hopped := false
	for i in 40:
		await _frames(1)
		hopped = hopped or _p.is_hopping()
	_p._input_override = Vector2.ZERO
	await _frames(5)
	_check("walking into a ledge hops down", hopped)
	_check("Joe lands below the ledge", _cell_of("south_road").y >= 7, str(_cell_of("south_road")))
	_check("hop and landing sounds", root.get_node("Audio").played_recently("land", 20))
	await _go("south_road", [23, 7], Vector2i.UP)
	await _hold(Vector2.UP, 40)
	_check("a ledge cannot be climbed from below", _cell_of("south_road").y == 7, str(_cell_of("south_road")))


func _t_water_is_solid() -> void:
	await _go("east_lake", [11, 6])
	await _hold(Vector2.RIGHT, 60)
	var local_x: float = _p.global_position.x - _w.origin_of("east_lake").x
	_check("the lake stops Joe at its shore", local_x <= 13.0 * TILE - 4.0, "x=%.1f" % local_x)


func _t_enemies_respawn() -> void:
	await _go("meadow_north", [23, 11])
	var first = _w.current["enemies"].duplicate()
	_check("the meadow has its three slimes", first.size() == 3, str(first.size()))
	await _go("el_pueblo", [23, 3])
	await _go("meadow_north", [23, 11])
	var again = _w.current["enemies"]
	_check("re-entering an area brings fresh enemies", again.size() == 3 and not is_instance_valid(first[0]))


func _t_death_respawn_at_entry() -> void:
	await _go("west_woods", [20, 13])
	var entry: Vector2 = _w.entry_point
	_p.global_position += Vector2(-40, 0)
	_p._on_hurt(99, _p.global_position + Vector2(0, -20), Vector2.ZERO)
	await _frames(int(FPS * 1.7))
	_check("death opens the Game Over screen and pauses the world", _w.game_over.is_open and paused)
	await _frames(int(FPS * 1.3))
	_check("the Game Over choices appear after the fade", _w.game_over.is_ready_to_choose())
	_w.game_over.menu.confirm()                    # CONTINUE is the first row
	await _frames(3)
	_check("Joe gets back up where he entered the area", _p.global_position == entry and not _p.is_dead()
			and not paused, "%s vs %s" % [_p.global_position, entry])
