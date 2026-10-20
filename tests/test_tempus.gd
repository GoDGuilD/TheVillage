# File: test_tempus.gd
# Description: Headless scripted checks for Phase 11 (Tempus): the region's data and way in, the molten-time gate (ice rod), tick blocks and the World's broken clock (swap, never rising under Joe), the Hammer (pegs, the way south to the piece of heart), cogbugs (armour, flipping), the clocktower's pegged doorway, and the Clock Warden (gears, time stop, cracked armour) with the third crystal.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-23
# Last edit date: 2026-10-23
# Version: 1.0.0
# Run:  Godot_console --headless --fixed-fps 60 --path . -s tests/test_tempus.gd   (must end "0 failed")
extends SceneTree

const WORLD_SCENE := "res://src/world/World.tscn"
const TEST_SAVE := "user://test_tempus_save.json"
const COGBUG_SCRIPT := "res://src/enemies/Cogbug.gd"
const FPS := 60.0
const SCROLL_WAIT := 55
const WARP_WAIT := 40
const BOLT_WAIT := 12
const TICK_WAIT := 125                   # frames > World.TICK_TIME (2 s)
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
	await _t_molten_time()
	await _t_tick_blocks()
	await _t_tick_never_under_joe()
	await _t_hammer_pegs()
	await _t_cogbug()
	await _t_tower_doorway()
	await _t_clock_warden()
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


func _find(cls_name: String) -> Array:
	var out := []
	for n in _w.current["actors"].get_children():
		if n.get_script() != null and String(n.get_script().get_global_name()) == cls_name and not n.is_queued_for_deletion():
			out.append(n)
	return out


func _cell() -> Vector2i:
	return Vector2i(((_p.global_position - _w.origin_of(_w.current_id())) / TILE).floor())


func _cell_of(n: Node2D) -> Vector2i:
	return Vector2i(((n.global_position - _w.origin_of(_w.current_id())) / TILE + Vector2(0, 0.6)).floor())


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


func _clear_enemies() -> void:
	for e in _w.current["enemies"]:
		if is_instance_valid(e):
			e.queue_free()


func _hit(e: Node2D, damage: int, element: String = "") -> void:
	var hb := HitBox.new()
	hb.element = element
	e.hurt_box.last_hit = hb
	e._iframes_left = 0.0
	e._on_hurt(damage, e.global_position + Vector2(0, -30), Vector2.ZERO)
	hb.free()


func _use(item: String, facing: Vector2i, wait: int) -> void:
	_gs.give_item(item)
	_gs.equip(item)
	_gs.add_magic(_gs.MAX_MAGIC)
	_p.facing = facing
	await _tap("item")
	await _frames(wait)


func _walk_to(target: Vector2i, dir: Vector2, max_frames: int = 180) -> void:
	_p._input_override = dir
	for i in max_frames:
		await _frames(1)
		if _cell() == target or _p.is_falling() or _w.transitioning:
			break
	_p._input_override = Vector2.ZERO
	await _frames(2)


func _collect_pickups() -> void:
	for p in get_nodes_in_group("pickup"):
		_p.global_position = p.global_position
	await _frames(4)
	await _finish()
	await _frames(3)


# --- tests -------------------------------------------------------------------

func _t_data() -> void:
	var d: Dictionary = _w.dungeons.get("d6", {})
	_check("the Tempus Clocktower holds the third crystal", int(d.get("crystal", -1)) == 2 and not d.has("seal")
			and String(d.get("entrance", "")) == "d6_entrance", str(d))
	_check("the Clockwork Wastes is a Dark World-only land west of the Broken Road", _w.is_dark("dw_clockwork_wastes")
			and _w.origin_of("dw_clockwork_wastes") == Vector2(-24, 42) * TILE)
	_check("the hammer is a Y-item", _gs.ITEM_ORDER.has("hammer") and ItemDB.KINDS.has("hammer"))


func _t_way_in() -> void:
	await _go("dw_south_road", [2, 9], Vector2i.LEFT)
	_p._input_override = Vector2.LEFT
	await _frames(SCROLL_WAIT)
	_p._input_override = Vector2.ZERO
	var guard := 0
	while _w.transitioning and guard < 120:            # let the scroll finish (it sets Joe's entry point)
		guard += 1
		await _frames(1)
	_check("the Broken Road runs west into the Clockwork Wastes", _w.current_id() == "dw_clockwork_wastes", _w.current_id())
	var door: Array = _w.areas["dw_clockwork_wastes"]["doors"]
	_check("the wastes' door leads into the clocktower", door.size() == 1 and String(door[0]["to"]) == "d6_entrance")


func _t_molten_time() -> void:
	await _go("dw_clockwork_wastes", [17, 9], Vector2i.LEFT)
	await _walk_to(Vector2i(13, 9), Vector2.LEFT, 60)
	await _frames(int(FPS * 1.2))
	_check("molten time burns like lava: no walking across", _w.falls == 1 and _cell().x >= 17, str(_cell()))
	_p.health.heal(_p.health.max_health)
	await _go("dw_clockwork_wastes", [17, 9], Vector2i.LEFT)
	await _use("ice_rod", Vector2i.LEFT, BOLT_WAIT)
	await _walk_to(Vector2i(13, 9), Vector2.LEFT)
	_check("the ice rod freezes a way over it", _cell() == Vector2i(13, 9) and not _p.is_falling(), str(_cell()))


func _t_tick_blocks() -> void:
	await _go("dw_clockwork_wastes", [8, 7], Vector2i.DOWN)
	var blocks: Array = _find("TickBlock")
	var ambers: Array = blocks.filter(func(b: Node) -> bool: return b.amber)
	var teals: Array = blocks.filter(func(b: Node) -> bool: return not b.amber)
	var phase: int = _w.tick_phase
	var up_ok := blocks.size() == 12 and ambers.all(func(b: Node) -> bool: return b.raised == (phase == 0)) \
			and teals.all(func(b: Node) -> bool: return b.raised == (phase == 1))
	_check("a fence of twelve tick blocks: one colour up, the other down", up_ok, "%d phase %d" % [blocks.size(), phase])
	var ticks: int = _w.ticks
	await _frames(TICK_WAIT)
	var swapped := ambers.all(func(b: Node) -> bool: return b.raised == (phase == 1)) \
			and teals.all(func(b: Node) -> bool: return b.raised == (phase == 0))
	_check("on the clock's tick the colours swap", _w.ticks == ticks + 1 and _w.tick_phase != phase and swapped)
	var a_cell: Vector2i = _cell_of(ambers[0])
	_check("a raised block is solid, a sunk one is walkable",
			(ambers[0].raised and not ambers[0]._shape.disabled) or (not ambers[0].raised and ambers[0]._shape.disabled),
			str(a_cell))


func _t_tick_never_under_joe() -> void:
	await _go("dw_clockwork_wastes", [8, 7], Vector2i.DOWN)
	var sunk: Node2D = null
	for b in _find("TickBlock"):
		if not b.raised:
			sunk = b
	_p.global_position = _w.cell_feet("dw_clockwork_wastes", [_cell_of(sunk).x, 10])
	await _frames(TICK_WAIT)
	_check("a block does not rise under Joe: it waits", sunk.pending and not sunk.raised)
	_p.global_position = _w.cell_feet("dw_clockwork_wastes", [_cell_of(sunk).x, 12])
	await _frames(4)
	_check("...and rises once he steps off", sunk.raised and not sunk.pending)


func _t_hammer_pegs() -> void:
	await _go("dw_clockwork_wastes", [6, 17], Vector2i.DOWN)
	var pegs: Array = _find("Peg")
	_check("a row of eleven pegs bars the way south", pegs.size() == 11 and pegs.all(func(p: Node) -> bool: return not p.is_down))
	await _use("hammer", Vector2i.DOWN, 20)
	var down: Array = pegs.filter(func(p: Node) -> bool: return p.is_down)
	_check("the hammer pounds the peg in front flat (only that one)", down.size() == 1 and _cell_of(down[0]).x == 6,
			str(down.size()))
	await _walk_to(Vector2i(6, 20), Vector2.DOWN)
	_check("Joe walks over it, south", _cell().y >= 19, str(_cell()))
	var pieces: int = _gs.heart_pieces
	_p.global_position = _w.cell_feet("dw_clockwork_wastes", [7, 23])
	await _frames(6)
	await _finish()
	_check("the wastes' piece of heart is his", _gs.heart_pieces == (pieces + 1) % 4, str(_gs.heart_pieces))
	await _go("dw_clockwork_wastes", [6, 17], Vector2i.DOWN)
	_check("pegs stand up again when the area is rebuilt", _find("Peg").all(func(p: Node) -> bool: return not p.is_down))


func _t_cogbug() -> void:
	await _go("d6_entrance", [11, 10], Vector2i.UP)
	_clear_enemies()
	var bug := _spawn(COGBUG_SCRIPT, _w.cell_feet("d6_entrance", [11, 9]))
	await _frames(2)
	var hp: int = bug.health.current_health
	_hit(bug, 2)
	_check("the sword clanks off a cogbug's shell", bug.health.current_health == hp and not bug.flipped)
	bug.position = _w.cell_feet("d6_entrance", [11, 9])
	_p.global_position = _w.cell_feet("d6_entrance", [11, 10])
	await _use("hammer", Vector2i.UP, 6)
	_check("a hammer swing flips it on its back", bug.flipped and bug.flips == 1)
	_hit(bug, 2)
	_check("on its back the sword hurts it", bug.health.current_health == hp - 2)
	await _frames(int(FPS * (bug.FLIP_TIME + 0.3)))
	_check("it rights itself after a while", not bug.flipped)
	bug.queue_free()


func _t_tower_doorway() -> void:
	await _go("d6_hall", [11, 4], Vector2i.UP)
	_clear_enemies()
	await _walk_to(Vector2i(11, 1), Vector2.UP, 60)
	_check("two pegs bar the hall's north doorway", _w.current_id() == "d6_hall" and _cell().y >= 3, str(_cell()))
	await _go("d6_hall", [11, 3], Vector2i.UP)
	await _use("hammer", Vector2i.UP, 20)
	_p._input_override = Vector2.UP
	await _frames(SCROLL_WAIT + 30)
	_p._input_override = Vector2.ZERO
	_check("with one pounded flat Joe walks through to the boss", _w.current_id() == "d6_boss", _w.current_id())


func _t_clock_warden() -> void:
	await _go("d6_boss", [11, 10], Vector2i.UP)
	var warden := _boss()
	_check("the Clock Warden waits in its room", warden != null
			and String(warden.get_script().get_global_name()) == "ClockWarden")
	var hp: int = warden.health.current_health
	_hit(warden, 4)
	_check("its armour turns the sword", warden.health.current_health == hp)
	await _frames(int(FPS * 1.7))
	_check("on its tick it throws gears four ways", warden.ticks >= 1 and warden.shots_fired >= 4, str(warden.shots_fired))
	var stopped := false
	for i in int(FPS * 4.0):
		await _frames(1)
		if warden.time_stops >= 1:
			stopped = _p._frozen_left > 0.0
			break
	_check("every third tick it stops Joe in time", stopped and warden.ticks >= 3)
	_hit(warden, 4, "hammer")
	_check("the hammer cracks its armour", warden.is_cracked() and warden.cracks == 1)
	_hit(warden, 4)
	_check("cracked, it can be struck", warden.health.current_health == hp - 4)
	_hit(warden, 2)
	_hit(warden, 2)
	_check("after three hits it stands again", not warden.is_cracked())
	var guard := 0
	while is_instance_valid(warden) and not warden.is_dead() and guard < 40:
		guard += 1
		if not warden.is_cracked():
			_hit(warden, 4, "hammer")
		_hit(warden, 4)
		await _frames(2)
	_check("the Clock Warden falls", not is_instance_valid(warden) or warden.is_dead())
	await _frames(int(FPS * 1.5))
	await _collect_pickups()
	await _collect_pickups()
	await _frames(WARP_WAIT)
	_check("the Crystal of Tempus is Joe's and he is back in the wastes", _gs.crystals[2]
			and _w.current_id() == "dw_clockwork_wastes", _w.current_id())
