# File: test_tower.gd
# Description: Headless scripted checks for Phase 13 (Caver's tower): the data (the final dungeon, its gate, the save spot after the ending), the crystal gate on the Dark World's keep, each floor's dimension trial (dark chasm and grapple, lava and ice rod, pegs and hammer, the pool and flippers), Caver's opening words, his fight (orbs batted back knock him down, the sword only lands then, bolt volleys, wings and bats below half health), his sinking, and the final ending, save and title.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-20
# Last edit date: 2026-10-20
# Version: 1.0.0
# Run:  Godot_console --headless --fixed-fps 60 --path . -s tests/test_tower.gd   (must end "0 failed")
extends SceneTree

const WORLD_SCENE := "res://src/world/World.tscn"
const TEST_SAVE := "user://test_tower_save.json"
const AREA_BUILDER := "res://src/world/AreaBuilder.gd"   # loaded, never named: it pulls in autoload users
const FPS := 60.0
const SCROLL_WAIT := 55
const WARP_WAIT := 40
const PULL_WAIT := 60                    # frames for a grapple shot + pull across seven tiles
const BOLT_WAIT := 40                    # frames for an ice bolt to fly its whole way
const TILE := 16.0
const TOWER_ROOMS := ["d8_entrance", "d8_umbra", "d8_ignis", "d8_tempus", "d8_silva", "d8_ante", "d8_boss"]

var _gs
var _w
var _p
var _ab
var _passed := 0
var _failed := 0


func _initialize() -> void:
	_gs = root.get_node("GameState")
	_gs.reset()
	_gs.drops_enabled = false
	_gs.set_flag("act1:done")
	_gs.set_flag("act2:started")
	_ab = load(AREA_BUILDER)
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
	await _t_crystal_gate()
	await _t_umbra_floor()
	await _t_ignis_floor()
	await _t_tempus_floor()
	await _t_silva_floor()
	await _t_intro()
	await _t_caver()
	await _t_ending()
	await _t_after_the_end()
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


func _boss() -> Node2D:
	for e in _w.current["enemies"]:
		if is_instance_valid(e) and e.get("is_boss"):
			return e
	return null


func _clear_enemies() -> void:
	for e in _w.current["enemies"]:
		if is_instance_valid(e) and not e.get("is_boss"):
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


func _settle() -> void:
	var guard := 0
	while _w.transitioning and guard < 120:            # let a scroll finish (it sets Joe's entry point)
		guard += 1
		await _frames(1)


# The terrain flag of an area cell right now ("lava", "water", ...).
func _flag(area: String, cell: Array, flag: String) -> bool:
	return _ab.flag_at(self, _w.origin_of(area) + (Vector2(float(cell[0]), float(cell[1])) + Vector2(0.5, 0.5)) * TILE, flag)


# --- tests ---------------------------------------------------------------------

func _t_data() -> void:
	var info: Dictionary = _w.dungeons.get("d8", {})
	_check("Caver's tower is the final dungeon: it ends the game, no seal, no crystal",
			String(info.get("ending", "")) == "final" and int(info.get("seal", 0)) == -1 and not info.has("crystal")
			and String(info.get("boss_room", "")) == "d8_boss", str(info))
	var rooms := TOWER_ROOMS.filter(func(r: String) -> bool: return _w.areas.has(r) and _w.dungeon_of(r) == "d8")
	_check("it has seven rooms, one floor per dimension", rooms.size() == TOWER_ROOMS.size(), str(rooms))
	var fields: Dictionary = _w.areas["dw_south_fields"]
	var gate: Array = fields["objects"].filter(func(o: Dictionary) -> bool: return o["kind"] == "crystal_gate")
	var doors: Array = fields["doors"].filter(func(d: Dictionary) -> bool: return d["to"] == "d8_entrance")
	_check("the crystal gate bars the Dark World's keep, and its gateway leads into the tower",
			gate.size() == 1 and doors.size() == 2)
	_check("the Umbra floor is dark; Caver's room has opening words", bool(_w.areas["d8_umbra"].get("dark", false))
			and String(_w.areas["d8_boss"].get("intro", "")) == "caver_tower_intro")
	_check("after the ending Joe is saved before the tower", String(_w.final_spawn.get("area", "")) == "dw_south_fields")
	var keys := ["crystal_gate", "crystal_gate_open", "caver_tower_intro", "caver_fall", "final_card"]
	_check("the gate, Caver and the ending have their words", keys.all(func(k: String) -> bool: return DialogueData.has(k)))


func _t_crystal_gate() -> void:
	for i in _gs.CRYSTAL_COUNT:
		_gs.crystals[i] = i != 2                  # Tempus missing
	await _go("dw_south_fields", [15, 7], Vector2i.UP)
	var gates: Array = _find("SealGate")
	_check("the tower's gate stands shut, its sockets lit for the crystals Joe holds", gates.size() == 1
			and gates[0].crystal and not gates[0].is_open and gates[0].lit_sockets() == 3, str(gates))
	await _tap("interact")
	var seen := await _finish()
	_check("with three crystals it will not open", not gates[0].is_open and seen.size() > 0, str(seen))
	_gs.crystals[2] = true
	_p.facing = Vector2i.UP
	await _tap("interact")
	await _finish()
	_check("with all four it opens for good", gates[0].is_open and _gs.has_flag("tower:gate")
			and gates[0].lit_sockets() == 4)
	await _go("dw_south_fields", [15, 8], Vector2i.UP)
	_check("and stays open", _find("SealGate")[0].is_open)
	_check("the Light World keep's gate is untouched", not _gs.has_flag("keep:gate"))
	_p._input_override = Vector2.UP
	await _frames(30)
	_p._input_override = Vector2.ZERO
	await _frames(WARP_WAIT)
	_check("the gateway leads into the tower", _w.current_id() == "d8_entrance", _w.current_id())


func _t_umbra_floor() -> void:
	await _go("d8_umbra", [8, 8], Vector2i.UP)
	_clear_enemies()
	_check("the Umbra floor is dark until its torches burn", _w.darkness.visible)
	var doors: Array = _find("Door").filter(func(d: Node) -> bool: return d.type == "locked")
	_check("its north door is locked", doors.size() == 1 and not doors[0].is_open)
	await _use("grapple", Vector2i.UP, PULL_WAIT)
	_check("the grapple pulls Joe over the chasm to the north side", _cell().y <= 4 and not _p.is_falling(),
			str(_cell()))


func _t_ignis_floor() -> void:
	await _go("d8_ignis", [11, 9], Vector2i.UP)
	_clear_enemies()
	_check("a band of lava cuts the Ignis floor", _flag("d8_ignis", [11, 6], "lava")
			and _flag("d8_ignis", [11, 4], "lava"))
	await _use("ice_rod", Vector2i.UP, BOLT_WAIT)
	var falls: int = _w.falls
	await _walk_to(Vector2i(11, 3), Vector2.UP, 120)
	_check("the ice rod freezes a way across", _cell().y <= 3 and _w.falls == falls, str(_cell()))


func _t_tempus_floor() -> void:
	await _go("d8_tempus", [11, 6], Vector2i.UP)
	_clear_enemies()
	var pegs: Array = _find("Peg")
	_check("a row of pegs bars the big door", pegs.size() == 20 and pegs.all(func(p: Node) -> bool: return not p.is_down),
			str(pegs.size()))
	await _walk_to(Vector2i(11, 2), Vector2.UP, 60)
	_check("Joe cannot pass them", _cell().y >= 4, str(_cell()))
	await _use("hammer", Vector2i.UP, 20)
	await _walk_to(Vector2i(11, 2), Vector2.UP, 60)
	_check("the hammer pounds one flat and Joe walks to the big door", _cell().y == 2, str(_cell()))
	var big: Array = _find("Door").filter(func(d: Node) -> bool: return d.type == "big")
	_check("the big door is shut", big.size() == 1 and not big[0].is_open)


func _t_silva_floor() -> void:
	_gs.items.erase("flippers")
	await _go("d8_silva", [19, 7], Vector2i.LEFT)
	_clear_enemies()
	var chests: Array = _find("Chest").filter(func(c: Node) -> bool: return c.kind == "big_key")
	_check("the big key waits on an islet in a deep pool", chests.size() == 1 and _flag("d8_silva", [12, 7], "water")
			and not _flag("d8_silva", [10, 7], "water"))
	await _walk_to(Vector2i(11, 7), Vector2.LEFT, 90)
	_check("without the flippers the pool stops Joe", _cell().x >= 18, str(_cell()))
	_w.grant("flippers")
	await _walk_to(Vector2i(11, 7), Vector2.LEFT, 240)
	_check("with them he swims to the islet", _cell().x <= 11, str(_cell()))


func _t_intro() -> void:
	_gs.give_dungeon_item("d8", "big_key")
	await _go("d8_ante", [11, 3], Vector2i.UP)
	_clear_enemies()
	_p._input_override = Vector2.UP
	for i in 200:
		await _frames(1)
		if _w.current_id() == "d8_boss" and not _w.transitioning:
			break
	_p._input_override = Vector2.ZERO
	await _settle()
	await process_frame
	await process_frame
	_check("the antechamber leads up to Caver's room", _w.current_id() == "d8_boss", _w.current_id())
	_check("Caver speaks as Joe walks in", _w.dialogue.is_open and _gs.has_flag("intro:d8_boss"))
	var seen := await _finish()
	_check("three pages of his words", seen.size() >= 3, str(seen.size()))
	var boss_door: Array = _find("Door").filter(func(d: Node) -> bool: return d.type == "boss")
	_check("the door shuts behind Joe", boss_door.size() == 1 and not boss_door[0].is_open)
	await _go("d8_boss", [11, 10], Vector2i.UP)
	_check("he says it only once", not _w.dialogue.is_open)


func _t_caver() -> void:
	await _go("d8_boss", [11, 10], Vector2i.UP)
	var caver := _boss()
	_check("Caver himself waits at the top", caver != null and String(caver.get_script().get_global_name()) == "CaverLord")
	var full: int = caver.health.current_health
	_hit(caver, 4)
	_check("floating, the sword cannot touch him", caver.health.current_health == full and not caver.is_dazed())
	for i in 120:
		await _frames(1)
		if caver.orbs_thrown >= 1:
			break
	_check("he casts a magic orb", caver.orbs_thrown >= 1 and not get_nodes_in_group("orb").is_empty())
	var shots: int = caver.shots_fired
	caver.casts = caver.VOLLEY_EVERY - 1
	caver.cast()
	_check("every third cast is a fan of dimension bolts", caver.volleys == 1
			and caver.shots_fired == shots + caver.VOLLEY_BOLTS, str(caver.shots_fired - shots))
	var orbs := get_nodes_in_group("orb")
	if orbs.is_empty():
		caver.throw_orb()
		await _frames(2)
		orbs = get_nodes_in_group("orb")
	orbs[0].bat_back()
	for i in 150:
		await _frames(1)
		if caver.is_dazed():
			break
	_check("an orb batted back knocks him down", caver.is_dazed() and caver.dazes == 1
			and caver.health.current_health == full - 1, str(caver.health.current_health))
	var hp: int = caver.health.current_health
	_hit(caver, 2)
	_check("knelt, the sword lands", caver.health.current_health == hp - 2)
	await _frames(int(FPS * (caver.DAZE_TIME + 0.3)))
	_check("he rises again and fades away", not caver.is_dazed())
	caver.health.current_health = caver.health.max_health / 2
	caver.phase = "fade_in"
	caver._timer = 0.05
	await _frames(12)
	_check("below half health his cape spreads into wings and he calls a bat", caver.is_angry()
			and caver.bats_called == 1 and caver.sprite.animation.begins_with("rage"), caver.sprite.animation)
	shots = caver.shots_fired
	caver.casts = caver.VOLLEY_EVERY_ANGRY - 1
	caver.cast()
	_check("angry, his volleys are full rings", caver.shots_fired == shots + caver.RING_BOLTS)
	for i in caver.MAX_BATS + 2:
		caver.call_bat()
	_check("no more than two of his bats fly at once", caver.bats_called == caver.MAX_BATS)
	for n in get_nodes_in_group("orb"):
		n.queue_free()


func _t_ending() -> void:
	var caver := _boss()
	caver.casts = caver.VOLLEY_EVERY_ANGRY - 1
	caver.cast()                                          # bolts in the air as he falls
	var guard := 0
	while is_instance_valid(caver) and not caver.is_dead() and guard < 30:
		guard += 1
		if not caver.is_dazed():
			_hit(caver, 1, "orb")
		if not caver.is_dead():
			_hit(caver, 2)
		await _frames(2)
	_check("Caver falls", is_instance_valid(caver) and caver.is_dead() and caver.phase == "sinking")
	await _frames(int(FPS * 0.7))
	_check("he sinks through the floor instead of bursting", is_instance_valid(caver) and caver.sprite.scale.y < 0.8
			and caver.sprite.scale.y > 0.0, str(caver.sprite.scale.y if is_instance_valid(caver) else -1.0))
	_check("his bats die with him", get_nodes_in_group("caver_bat").filter(func(b: Node) -> bool:
			return not b.is_queued_for_deletion()).is_empty())
	_check("and his bolts and orbs still in the air vanish", (get_nodes_in_group("enemy_shot")
			+ get_nodes_in_group("orb")).filter(func(n: Node) -> bool: return not n.is_queued_for_deletion()).is_empty())
	await _frames(int(FPS * 1.2))
	_check("his last words, the game marked done", _w.endings == 1 and _w.dialogue.is_open
			and _gs.has_flag("final:done") and _gs.has_flag("boss:d8"))
	var words := await _finish()
	_check("three pages of them", words.size() >= 3, str(words.size()))
	_check("then the final card", _w.end_card.is_open)
	var guard2 := 0
	while not _w.end_card.ready_to_close and guard2 < 900:
		guard2 += 1
		await process_frame
	_check("its six lines appear one by one", _w.end_card.lines_shown == 6, str(_w.end_card.lines_shown))
	var world = _w
	_w.end_card.close()
	await process_frame
	await process_frame
	var data := SaveGame.read()
	_check("the game is saved before the tower, the ending marked", String(data.get("area", "")) == "dw_south_fields"
			and bool(data["state"]["flags"].get("final:done", false)), str(data.get("area", "")))
	_check("and the title screen comes back", current_scene != null and current_scene != world
			and String(current_scene.scene_file_path).ends_with("TitleScreen.tscn"), str(current_scene))


func _t_after_the_end() -> void:
	if current_scene != null:
		current_scene.queue_free()
	await process_frame
	await _new_world()
	await _go("d8_boss", [11, 10], Vector2i.UP)
	_check("back in the tower, Caver's room stays empty and silent", _boss() == null and not _w.dialogue.is_open)
	_check("the tower's gate stays open", _gs.has_flag("tower:gate"))
