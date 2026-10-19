# File: test_act1.gd
# Description: Headless scripted checks for Phase 7: dungeon data for Ram's Hollow, the Frost Vault and Caver's Keep, magic jars, the road south, the dash boots (dash, bonk, rubble, dash damage), the fire rod (fireball, torches, magic), bats, the Iron Ram, the Frost Wraith, the seal gate, Caver's shade and the end of Act 1.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-19
# Last edit date: 2026-10-20
# Version: 1.0.1
# Run:  Godot_console --headless --fixed-fps 60 --path . -s tests/test_act1.gd   (must end "0 failed")
extends SceneTree

const WORLD_SCENE := "res://src/world/World.tscn"
const SLIME_SCRIPT := "res://src/enemies/Slime.gd"
const BAT_SCRIPT := "res://src/enemies/Bat.gd"
const PICKUP_SCRIPT := "res://src/world/Pickup.gd"
const TEST_SAVE := "user://test_act1_save.json"
const FPS := 60.0
const SCROLL_WAIT := 55
const WARP_WAIT := 45

var _gs
var _audio
var _w
var _p
var _passed := 0
var _failed := 0


func _initialize() -> void:
	_gs = root.get_node("GameState")
	_audio = root.get_node("Audio")
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
	await _t_magic_jars()
	await _t_road_south()
	await _t_dash()
	await _t_rubble()
	await _t_fire_rod()
	await _t_bat()
	await _t_iron_ram()
	await _t_frost_wraith()
	await _t_seal_gate()
	await _t_caver_and_ending()
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


func _boss() -> Node2D:
	for e in _w.current["enemies"]:
		if is_instance_valid(e) and e.get("is_boss"):
			return e
	return null


func _slime_at(feet: Vector2) -> Node2D:
	var s: Node2D = load(SLIME_SCRIPT).new()
	s.position = feet
	s.player = _p
	_w.current["actors"].add_child(s)
	return s


# Hit `e` the way a given weapon would (a HitBox with an element), through the normal hurt path.
func _hit(e: Node2D, damage: int, element: String = "") -> void:
	var hb := HitBox.new()
	hb.element = element
	e.hurt_box.last_hit = hb
	e._iframes_left = 0.0
	e._on_hurt(damage, e.global_position + Vector2(0, -30), Vector2.ZERO)
	hb.free()


# Defeat the boss of the current room and collect the heart container and the seal (which warps Joe out).
func _beat_boss_and_collect(boss: Node2D, element: String = "") -> void:
	var guard := 0
	while is_instance_valid(boss) and not boss.is_dead() and guard < 40:
		guard += 1
		if boss.has_method("is_dazed") and not boss.is_dazed():
			boss.state = "dazed"
			boss._timer = 5.0
		_hit(boss, 4, element)
		await _frames(2)
	await _frames(int(FPS * 1.5))
	for p in get_nodes_in_group("pickup"):
		_p.global_position = p.global_position
	await _frames(4)
	await _finish()
	await _frames(3)
	for p in get_nodes_in_group("pickup"):
		_p.global_position = p.global_position
	await _frames(4)
	await _finish()
	await _frames(WARP_WAIT)


# --- tests -------------------------------------------------------------------

func _t_data() -> void:
	var d: Dictionary = _w.dungeons
	_check("four dungeons are listed", d.has("d1") and d.has("d2") and d.has("d3") and d.has("keep"), str(d.keys()))
	_check("seals 1 and 2 belong to the new dungeons", int(d["d2"]["seal"]) == 1 and int(d["d3"]["seal"]) == 2)
	_check("the keep ends Act 1 and holds no seal", String(d["keep"].get("ending", "")) == "act1" and int(d["keep"]["seal"]) < 0)
	var counts := {"d2": 0, "d3": 0, "keep": 0}
	for aid in _w.areas:
		var dg: String = _w.dungeon_of(aid)
		if counts.has(dg):
			counts[dg] += 1
	_check("six rooms each for the Hollow and the Vault, three for the keep",
			counts["d2"] == 6 and counts["d3"] == 6 and counts["keep"] == 3, str(counts))
	var missing := []
	for key in ["get_boots", "get_fire_rod", "get_seal_1", "get_seal_2", "seal_gate", "seal_gate_open", "caver_banish",
			"act1_card", "sign_fields", "sign_keep"]:
		if not DialogueData.has(key):
			missing.append(key)
	_check("every Act 1 text exists", missing.is_empty(), str(missing))


func _t_magic_jars() -> void:
	await _go("el_pueblo", [8, 9])
	_gs.magic = 0
	_gs.add_magic(0)
	for kind in ["magic_small", "magic_big"]:
		var jar: Area2D = load(PICKUP_SCRIPT).new()
		jar.kind = kind
		jar.position = _p.global_position
		_w.current["actors"].add_child(jar)
		await _frames(12)
	_check("a small and a big jar refill 4 + 16 magic", _gs.magic == 20 and _w.hud.magic_shown == 20, str(_gs.magic))
	var total := 0
	var jars := 0
	for row in _gs.DROP_TABLE:
		total += int(row[1])
		if String(row[0]).begins_with("magic"):
			jars += int(row[1])
	_check("magic jars are in the drop table", jars > 0 and total == 100, "%d/%d" % [jars, total])
	_gs.add_magic(99)


func _t_road_south() -> void:
	await _go("south_road", [22, 11], Vector2i.DOWN)
	var rocks := _find("HeavyRock")
	_check("heavy rocks close the way south", rocks.size() == 4)
	_gs.give_item("glove")
	await _tap("interact")
	await _frames(15)
	_check("the glove lifts one", _p.carrying == "rock")
	_p.facing = Vector2i.UP
	await _tap("interact")
	await _frames(30)
	_p.facing = Vector2i.DOWN
	_p._input_override = Vector2.DOWN
	await _frames(70)
	_p._input_override = Vector2.ZERO
	await _frames(SCROLL_WAIT)
	_check("through the gap Joe reaches the South Fields", _w.current_id() == "south_fields", _w.current_id())


func _t_dash() -> void:
	await _go("el_pueblo", [8, 13], Vector2i.RIGHT)
	await _tap("dash")
	await _frames(5)
	_check("without the boots the dash button does nothing", _p.fsm.current_state == "idle", _p.fsm.current_state)
	_gs.give_item("boots")
	_check("the boots are not an equippable Y-item", _gs.equipped != "boots")
	var x0: float = _p.global_position.x
	await _tap("dash")
	await _frames(3)
	_check("with the boots Joe runs on the spot first", _p.fsm.current_state == "dash_charge", _p.fsm.current_state)
	await _frames(30)
	_check("then dashes", _p.is_dashing())
	await _frames(10)
	_check("much faster than walking", _p.global_position.x - x0 > 40.0, str(_p.global_position.x - x0))
	# A dash into a house wall must bonk.
	await _go("joe_house", [4, 6], Vector2i.LEFT)
	await _tap("dash")
	var bonked := false
	for i in 90:
		await _frames(1)
		if _p.fsm.current_state == "bonk":
			bonked = true
			break
	_check("a dash into a wall ends in a bonk", bonked)
	await _frames(30)
	_check("and Joe recovers", _p.fsm.current_state == "idle", _p.fsm.current_state)
	await _go("el_pueblo", [8, 13], Vector2i.RIGHT)
	var slime := _slime_at(_w.cell_feet("el_pueblo", [14, 13]))
	slime.freeze(10.0)
	await _tap("dash")
	await _frames(60)
	_check("the sword held out during a dash kills what it meets", not is_instance_valid(slime) or slime.is_dead())


func _t_rubble() -> void:
	await _go("south_fields", [40, 19], Vector2i.UP)
	_check("rubble chokes the gap in the Vault's fence", _find("Rubble").size() == 1)
	_p._input_override = Vector2.UP
	await _frames(20)
	_p._input_override = Vector2.ZERO
	_check("walking into it does nothing", _find("Rubble").size() == 1)
	await _go("south_fields", [40, 19], Vector2i.UP)
	await _tap("dash")
	await _frames(40)
	_check("a dash breaks it", _find("Rubble").is_empty() and _gs.has_flag(_w.object_flag("rubble", "south_fields", [40, 17])))
	await _go("el_pueblo", [8, 9])
	await _go("south_fields", [40, 19], Vector2i.UP)
	_check("and it stays broken", _find("Rubble").is_empty())


func _t_fire_rod() -> void:
	_gs.give_item("fire_rod")
	_gs.equip("fire_rod")
	_gs.add_magic(99)
	await _go("d3_west", [6, 6], Vector2i.UP)
	var magic: int = _gs.magic
	await _tap("item")
	_check("a fireball costs magic", _gs.magic == magic - 4, "%d -> %d" % [magic, _gs.magic])
	_check("and flies", get_nodes_in_group("fireball").size() == 1)
	await _frames(30)
	var lit := _find("Torch").filter(func(t: Node) -> bool: return t.lit).size()
	_check("it lights a torch from afar", lit == 1, str(lit))
	await _frames(15)
	_p.global_position = _w.cell_feet("d3_west", [15, 6])     # same visit: rebuilding the room puts torches out
	_p.facing = Vector2i.UP
	await _frames(2)
	await _tap("item")
	await _frames(40)
	var chest := _find("Chest").filter(func(c: Node) -> bool: return c.reveal_by == "torches")
	_check("both torches lit reveal the small key's chest", chest.size() == 1 and not chest[0].concealed)
	_gs.magic = 2
	await _frames(15)
	await _tap("item")
	await _frames(3)
	_check("not enough magic, no fireball", get_nodes_in_group("fireball").is_empty() and _audio.played_recently("error"))
	_gs.add_magic(99)


func _t_bat() -> void:
	await _go("d1_hub", [11, 10])
	var bat: Node2D = load(BAT_SCRIPT).new()
	bat.position = _w.cell_feet("d1_hub", [5, 6])
	bat.player = null
	_w.current["actors"].add_child(bat)
	await _frames(2)
	var crossed := false
	for i in 300:
		bat._dir = Vector2.UP
		bat._leg_left = 1.0
		await _frames(1)
		if load("res://src/world/AreaBuilder.gd").flag_at(self, bat.global_position + Vector2(0, -3), "pit"):
			crossed = true
			break
	_check("a bat flies over pits", crossed)
	_hit(bat, 2)
	await _frames(3)
	_check("one hit kills it", not is_instance_valid(bat) or bat.is_dead())


func _t_iron_ram() -> void:
	await _go("d2_boss", [11, 10], Vector2i.UP)
	var ram := _boss()
	_check("the Iron Ram waits in its room", ram != null and String(ram.get_script().get_global_name()) == "IronRam")
	var hp: int = ram.health.current_health
	_hit(ram, 4)
	_check("its armour turns the sword while it is not dazed", ram.health.current_health == hp)
	ram.position = _w.cell_feet("d2_boss", [11, 5])
	_p.global_position = _w.cell_feet("d2_boss", [11, 10])
	var dazed := false
	for i in 300:
		await _frames(1)
		if ram.is_dazed():
			dazed = true
			break
	_check("it lines up, charges and dazes itself on a wall", dazed and ram.charges >= 1, "%s %d" % [ram.state, ram.charges])
	hp = ram.health.current_health
	_hit(ram, 4)
	_check("a dazed ram can be hurt", ram.health.current_health == hp - 4)
	await _beat_boss_and_collect(ram)
	_check("beating it gives the second seal and leads back out", _gs.seals[1] and _w.current_id() == "south_fields",
			_w.current_id())


func _t_frost_wraith() -> void:
	await _go("d3_boss", [11, 10], Vector2i.UP)
	var wraith := _boss()
	_check("the Frost Wraith floats in its room", wraith != null and String(wraith.get_script().get_global_name()) == "FrostWraith")
	var hp: int = wraith.health.current_health
	_hit(wraith, 4)
	_hit(wraith, 4, "stun")
	_check("sword and boomerang do nothing to it", wraith.health.current_health == hp)
	var cast_seen := false
	for i in 220:
		await _frames(1)
		if not get_nodes_in_group("enemy_shot").is_empty():
			cast_seen = true
			break
	_check("it casts a fan of ice shards", cast_seen and get_nodes_in_group("enemy_shot").size() == 3)
	_hit(wraith, 4, "fire")
	_check("fire burns it", wraith.health.current_health == hp - 4)
	await _beat_boss_and_collect(wraith, "fire")
	_check("beating it gives the third seal and leads back out", _gs.seals[2] and _w.current_id() == "south_fields",
			_w.current_id())


func _t_seal_gate() -> void:
	_gs.seals[0] = false
	await _go("south_fields", [15, 7], Vector2i.UP)
	var gate: Array = _find("SealGate")
	_check("the keep's gate stands shut", gate.size() == 1 and not gate[0].is_open)
	await _tap("interact")
	var seen := await _finish()
	_check("with two seals it will not open", not gate[0].is_open and seen.size() > 0, str(seen))
	_gs.seals[0] = true
	_p.facing = Vector2i.UP
	await _tap("interact")
	await _finish()
	_check("with all three it opens for good", gate[0].is_open and _gs.has_flag("keep:gate"))
	await _go("south_fields", [15, 8], Vector2i.UP)
	_check("and stays open", _find("SealGate")[0].is_open)
	_p._input_override = Vector2.UP
	await _frames(30)
	_p._input_override = Vector2.ZERO
	await _frames(WARP_WAIT)
	_check("the gateway leads into the keep", _w.current_id() == "keep_entrance", _w.current_id())


func _t_caver_and_ending() -> void:
	await _go("keep_gallery", [11, 3], Vector2i.UP)
	_p._input_override = Vector2.UP
	await _frames(60)
	_p._input_override = Vector2.ZERO
	await _frames(SCROLL_WAIT)
	_check("the gallery leads up to the throne room", _w.current_id() == "keep_throne", _w.current_id())
	var caver := _boss()
	_check("Caver's shade waits there", caver != null and String(caver.get_script().get_global_name()) == "CaverShade")
	_hit(caver, 4)
	_check("the sword cannot touch him", caver.health.current_health == caver.health.max_health)
	var thrown := false
	for i in 200:
		await _frames(1)
		if not get_nodes_in_group("orb").is_empty():
			thrown = true
			break
	_check("he throws a magic orb", thrown)
	var wounds := 0
	var guard := 0
	while is_instance_valid(caver) and not caver.is_dead() and guard < 12:
		guard += 1
		var hp: int = caver.health.current_health
		var orbs := get_nodes_in_group("orb")
		if orbs.is_empty():
			caver.throw_orb()
			await _frames(2)
			orbs = get_nodes_in_group("orb")
		orbs[0].bat_back()
		for i in 120:
			await _frames(1)
			if not is_instance_valid(caver) or caver.is_dead() or caver.health.current_health < hp:
				break
		if not is_instance_valid(caver) or caver.is_dead() or caver.health.current_health < hp:
			wounds += 1
	_check("three orbs batted back defeat the shade", wounds == 3 and (not is_instance_valid(caver) or caver.is_dead()),
			str(wounds))
	await _frames(int(FPS * 2.0))
	_check("Caver speaks his last words", _w.endings == 1 and _w.dialogue.is_open and _gs.has_flag("act1:done"))
	await _finish()
	_check("then the end-of-act card", _w.end_card.is_open)
	var guard2 := 0
	while not _w.end_card.ready_to_close and guard2 < 600:
		guard2 += 1
		await process_frame
	_check("its lines appear one by one", _w.end_card.lines_shown == 5, str(_w.end_card.lines_shown))
	var world = _w
	_w.end_card.close()
	await process_frame
	await process_frame
	var data := SaveGame.read()
	_check("the game is saved where the spell drops Joe (the Dark World), the act marked done", String(data.get("area", "")) == "dw_el_pueblo"
			and bool(data["state"]["flags"].get("act1:done", false)), str(data.get("area", "")))
	_check("and the title screen comes back", current_scene != null and current_scene != world
			and String(current_scene.scene_file_path).ends_with("TitleScreen.tscn"), str(current_scene))
