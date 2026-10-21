# File: test_umbra.gd
# Description: Headless scripted checks for Phase 9 (Umbra): the region's data and way in, the mirror in a Dark World-only land, the grapple (hook posts, walls, stunning, the island's piece of heart), lurkers, dark rooms and their torches, the Umbra Sanctum's chasm and switch, the Gloom Moth and the first dimension crystal, the Shade Market, and crystals in saves and the item menu.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-21
# Last edit date: 2026-10-20
# Version: 1.1.0
# Run:  Godot_console --headless --fixed-fps 60 --path . -s tests/test_umbra.gd   (must end "0 failed")
extends SceneTree

const WORLD_SCENE := "res://src/world/World.tscn"
const TEST_SAVE := "user://test_umbra_save.json"
const SLIME_SCRIPT := "res://src/enemies/Slime.gd"
const LURKER_SCRIPT := "res://src/enemies/Lurker.gd"
const FPS := 60.0
const SCROLL_WAIT := 55
const WARP_WAIT := 40
const PULL_WAIT := 60                    # frames for a grapple shot + pull across seven tiles
const TILE := 16.0

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
	await _t_way_in()
	await _t_mirror_void()
	await _t_grapple_island()
	await _t_grapple_wall()
	await _t_grapple_stuns()
	await _t_lurker()
	await _t_dark_rooms()
	await _t_sanctum_chasm()
	await _t_gloom_moth()
	await _t_shade_market()
	await _t_crystals_kept()
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


# The open box's page once it has finished typing ("" if no box opened).
func _text() -> String:
	await _frames(int(FPS * 2.0))
	return _w.dialogue.visible_text() if _w.dialogue.is_open else ""


func _find(cls_name: String) -> Array:
	var out := []
	for n in _w.current["actors"].get_children():
		if n.get_script() != null and String(n.get_script().get_global_name()) == cls_name and not n.is_queued_for_deletion():
			out.append(n)
	return out


# The cell Joe's feet are in, in area coordinates.
func _cell() -> Vector2i:
	return Vector2i(((_p.global_position - _w.origin_of(_w.current_id())) / TILE).floor())


func _boss() -> Node2D:
	for e in _w.current["enemies"]:
		if is_instance_valid(e) and e.get("is_boss"):
			return e
	return null


func _spawn(script: String, feet: Vector2) -> Node2D:
	var e: Node2D = load(script).new()
	e.position = feet
	e.player = _p
	_w.current["actors"].add_child(e)
	return e


# Hit `e` the way a given weapon would (a HitBox with an element), through the normal hurt path.
func _hit(e: Node2D, damage: int, element: String = "") -> void:
	var hb := HitBox.new()
	hb.element = element
	e.hurt_box.last_hit = hb
	e._iframes_left = 0.0
	e._on_hurt(damage, e.global_position + Vector2(0, -30), Vector2.ZERO)
	hb.free()


# Shoot the grapple from where Joe stands, facing `facing`, and wait for the shot (and any pull) to end.
func _grapple(facing: Vector2i) -> void:
	_gs.equip("grapple")
	_p.facing = facing
	await _tap("item")
	await _frames(PULL_WAIT)


func _collect_pickups() -> void:
	for p in get_nodes_in_group("pickup"):
		_p.global_position = p.global_position
	await _frames(4)
	await _finish()
	await _frames(3)


# --- tests -------------------------------------------------------------------

func _t_data() -> void:
	var d: Dictionary = _w.dungeons.get("d4", {})
	_check("the Umbra Sanctum holds the first crystal (no seal)", int(d.get("crystal", -1)) == 0 and not d.has("seal")
			and String(d.get("entrance", "")) == "d4_entrance", str(d))
	var vale: Dictionary = _w.areas.get("dw_umbra_vale", {})
	_check("the Umbral Vale is a Dark World-only land north of the meadow", _w.is_dark("dw_umbra_vale")
			and not _w.areas.has("umbra_vale") and _w.origin_of("dw_umbra_vale") == Vector2(0, -14) * TILE,
			str(vale.get("origin_tiles", [])))
	var dark: Array = []
	for aid in _w.areas:
		if bool(_w.areas[aid].get("dark", false)) and _w.dungeon_of(aid) == "d4":
			dark.append(aid)
	dark.sort()
	_check("two of the sanctum's rooms are dark", dark == ["d4_hall", "d4_west"], str(dark))
	_check("the grapple is a Y-item, the crystal and magic are kinds", _gs.ITEM_ORDER.has("grapple")
			and ItemDB.KINDS.has("grapple") and ItemDB.KINDS.has("crystal") and ItemDB.KINDS.has("magic"))
	_check("four crystal sockets, none filled", _gs.crystals.size() == 4 and _gs.crystal_count() == 0)
	_check("the Shade Market's wares cost more than Boni's", int(ItemDB.WARES["dw_bombs"]["price"])
			> int(ItemDB.WARES["bombs"]["price"]) and String(ItemDB.WARES["dw_magic"]["kind"]) == "magic")


func _t_way_in() -> void:
	await _go("dw_meadow_north", [23, 1], Vector2i.UP)
	_p._input_override = Vector2.UP
	await _frames(SCROLL_WAIT)
	_p._input_override = Vector2.ZERO
	_check("the Withered Meadow's trees part north into the Umbral Vale", _w.current_id() == "dw_umbra_vale",
			_w.current_id())
	var door: Array = _w.areas["dw_umbra_vale"]["doors"]
	_check("the vale's shrine door leads into the sanctum", door.size() == 1 and String(door[0]["to"]) == "d4_entrance")


func _t_mirror_void() -> void:
	_gs.give_item("moon_mirror")
	_gs.equip("moon_mirror")
	await _go("dw_umbra_vale", [23, 8], Vector2i.DOWN)
	var warps: int = _w.world_warps
	await _tap("item")
	var text := await _text()
	await _finish()
	_check("the Moon Mirror does nothing in a land with no waking twin", _w.world_warps == warps
			and _w.current_id() == "dw_umbra_vale" and text.contains("darkness"), text)


func _t_grapple_island() -> void:
	_gs.give_item("grapple")
	await _go("dw_umbra_vale", [29, 6], Vector2i.RIGHT)
	var post: Array = _find("HookPost")
	_check("two hook posts stand by the chasm", post.size() == 2)
	await _grapple(Vector2i.RIGHT)
	_check("the grapple bites the island's post and pulls Joe across the chasm", _cell() == Vector2i(35, 6), str(_cell()))
	_check("the chain is reeled in and Joe walks again", get_nodes_in_group("grapple").is_empty()
			and _p.fsm.current_state == "idle" and _p.collision_mask != 0, _p.fsm.current_state)
	await _frames(20)
	_check("he did not fall (the island is solid ground)", not _p.is_falling() and _w.falls == 0)
	var pieces: int = _gs.heart_pieces
	_p.global_position = _w.cell_feet("dw_umbra_vale", [34, 5])
	await _frames(6)
	await _finish()
	_check("the island's piece of heart is his", _gs.heart_pieces == (pieces + 1) % 4 or _gs.heart_pieces == pieces + 1,
			str(_gs.heart_pieces))
	await _go("dw_umbra_vale", [33, 7], Vector2i.LEFT)
	await _grapple(Vector2i.LEFT)
	_check("the mainland post brings him back", _cell() == Vector2i(29, 7), str(_cell()))


func _t_grapple_wall() -> void:
	await _go("d4_entrance", [3, 6], Vector2i.LEFT)
	var at: Vector2 = _p.global_position
	_gs.equip("grapple")
	await _tap("item")
	await _frames(3)
	var out := not get_nodes_in_group("grapple").is_empty()
	await _frames(PULL_WAIT)
	_check("against a wall the claw comes straight back and Joe stays put", out
			and get_nodes_in_group("grapple").is_empty() and _p.global_position.distance_to(at) < 1.0,
			str(_p.global_position - at))
	await _go("d4_entrance", [11, 9], Vector2i.UP)
	at = _p.global_position
	await _grapple(Vector2i.UP)
	_check("with nothing to bite it runs out of chain and returns", get_nodes_in_group("grapple").is_empty()
			and _p.global_position.distance_to(at) < 1.0)


func _t_grapple_stuns() -> void:
	await _go("d4_entrance", [11, 10], Vector2i.UP)
	for e in _w.current["enemies"]:
		e.queue_free()
	var slime := _spawn(SLIME_SCRIPT, _w.cell_feet("d4_entrance", [11, 7]))
	await _frames(2)
	var hp: int = slime.health.current_health
	_gs.equip("grapple")
	await _tap("item")
	var stunned := false
	for i in 40:
		await _frames(1)
		if slime._frozen_left > 0.0:
			stunned = true
			break
	_check("the grapple stuns an enemy without hurting it", stunned and slime.health.current_health == hp)
	await _frames(PULL_WAIT)
	_check("...and comes back", get_nodes_in_group("grapple").is_empty())


func _t_lurker() -> void:
	await _go("d4_entrance", [11, 10], Vector2i.RIGHT)
	for e in _w.current["enemies"]:
		e.queue_free()
	var lurker := _spawn(LURKER_SCRIPT, _w.cell_feet("d4_entrance", [17, 10]))
	await _frames(2)
	var at: Vector2 = lurker.global_position
	await _frames(30)
	_check("a lurker Joe looks at freezes", lurker.watched and lurker.global_position.distance_to(at) < 0.5,
			str(lurker.global_position - at))
	_p.facing = Vector2i.LEFT
	await _frames(30)
	_check("it creeps closer while his back is turned", not lurker.watched
			and lurker.global_position.distance_to(_p.global_position) < at.distance_to(_p.global_position) - 8.0)
	lurker.queue_free()


func _t_dark_rooms() -> void:
	await _go("d4_entrance", [11, 6], Vector2i.UP)
	_check("the sanctum's entrance is lit", not _w.darkness.visible)
	_gs.reset()
	_gs.drops_enabled = false
	await _go("d4_hall", [11, 11], Vector2i.UP)
	_check("the hall is dark: only a little light around Joe", _w.darkness.visible
			and _w.darkness.texture == _w.DARK_SMALL)
	_gs.give_item("lantern")
	await _go("d4_hall", [11, 11], Vector2i.UP)
	_check("the lantern widens the light", _w.darkness.visible and _w.darkness.texture == _w.DARK_LANTERN)
	var torches: Array = _find("Torch")
	for t in torches:
		t.light()
	await _frames(3)
	var map_chest := false
	for c in _find("Chest"):
		map_chest = map_chest or (c.kind == "map" and not c.concealed)
	_check("lighting both torches lights the room and shows the map's chest", torches.size() == 2
			and not _w.darkness.visible and map_chest)
	await _go("d4_west", [20, 6], Vector2i.LEFT)
	_check("the west room is dark too (its torches start cold)", _w.darkness.visible)


func _t_sanctum_chasm() -> void:
	_gs.give_item("grapple")
	await _go("d4_east", [12, 6], Vector2i.RIGHT)
	await _grapple(Vector2i.RIGHT)
	_check("in the east room the grapple crosses the chasm", _cell() == Vector2i(16, 6), str(_cell()))
	var sw: Array = _find("FloorSwitch")
	_p.global_position = _w.cell_feet("d4_east", [19, 3])
	await _frames(10)
	_check("the switch beyond it clicks down", sw.size() == 1 and _gs.has_flag("switch:d4_east"))
	await _go("d4_east", [16, 9], Vector2i.LEFT)
	await _grapple(Vector2i.LEFT)
	_check("the west post brings Joe back", _cell() == Vector2i(12, 9), str(_cell()))
	await _go("d4_hall", [11, 4], Vector2i.UP)
	var north_open := false
	for d in _find("Door"):
		if d.dir == "n":
			north_open = d.is_open
	_check("the hall's north shutter is open now", north_open)


func _t_gloom_moth() -> void:
	await _go("d4_boss", [11, 10], Vector2i.UP)
	var moth := _boss()
	_check("the Gloom Moth waits in its room", moth != null and String(moth.get_script().get_global_name()) == "GloomMoth")
	var hp: int = moth.health.current_health
	_hit(moth, 4)
	_check("in the air the sword cannot reach it", moth.health.current_health == hp and not moth.is_grounded())
	await _frames(int(FPS * 2.6))
	_check("it scatters dust at Joe", moth.shots_fired >= 3, str(moth.shots_fired))
	_hit(moth, 0, "hook")
	_check("the grapple drags it to the ground", moth.is_grounded() and moth.groundings == 1)
	_hit(moth, 4)
	_check("on the ground it can be struck", moth.health.current_health == hp - 4)
	await _frames(int(FPS * 3.3))
	_check("it takes off again after a while", not moth.is_grounded())
	var guard := 0
	while is_instance_valid(moth) and not moth.is_dead() and guard < 40:
		guard += 1
		if not moth.is_grounded():
			_hit(moth, 0, "hook")
		_hit(moth, 4)
		await _frames(2)
	_check("the Gloom Moth falls", not is_instance_valid(moth) or moth.is_dead())
	await _frames(int(FPS * 1.5))
	await _collect_pickups()
	await _collect_pickups()
	await _frames(WARP_WAIT)
	_check("the Crystal of Umbra is Joe's and he is back in the vale", _gs.crystals[0] and _gs.crystal_count() == 1
			and _w.current_id() == "dw_umbra_vale", _w.current_id())


func _t_shade_market() -> void:
	await _go("dw_el_pueblo", [10, 18], Vector2i.UP)
	var wares: Array = _find("ShopItem")
	var ids: Array = wares.map(func(w: Node) -> String: return w.ware)
	ids.sort()
	_check("the Shade Market sells three wares", ids == ["dw_arrows", "dw_bombs", "dw_magic"], str(ids))
	var magic_ware: Node2D = null
	for w in wares:
		if w.ware == "dw_magic":
			magic_ware = w
	_gs.add_gems(100 - _gs.gems)
	_gs.add_magic(-_gs.MAX_MAGIC)
	var ok: bool = _w.buy(magic_ware)
	var text := await _text()
	await _finish()
	_check("a bottle of magic fills the meter for 40 gems", ok and _gs.magic == _gs.MAX_MAGIC and _gs.gems == 60)
	_check("the shade thanks Joe in its own words", text.contains("Mind the dark"), text)
	ok = _w.buy(magic_ware)
	text = await _text()
	await _finish()
	_check("a full meter turns the sale down", not ok and _gs.gems == 60 and text.contains("full already"), text)


func _t_crystals_kept() -> void:
	var snap: Dictionary = _gs.snapshot()
	_gs.reset()
	_check("a fresh game has no crystals", _gs.crystal_count() == 0)
	_gs.restore(snap)
	_check("crystals survive a save and load", _gs.crystals[0] and _gs.crystal_count() == 1)
	_w.item_menu._refresh()
	_check("the item menu shows the crystal in its socket", _w.item_menu._crystals.size() == 4
			and _w.item_menu._crystals[0].texture == _w.item_menu.CRYSTAL_FULL_TEX
			and _w.item_menu._crystals[1].texture == _w.item_menu.CRYSTAL_EMPTY_TEX)
