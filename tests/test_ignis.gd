# File: test_ignis.gd
# Description: Headless scripted checks for Phase 10 (Ignis): the region's data and way in, the lava river and its hook posts, lava burning Joe, the Ice Rod (magic, frozen lava crust that thaws, frozen enemies), cinders and their flames, the Ignis Forge's islet and lava channel, and the Magma Wyrm with the second dimension crystal.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-22
# Last edit date: 2026-10-22
# Version: 1.0.0
# Run:  Godot_console --headless --fixed-fps 60 --path . -s tests/test_ignis.gd   (must end "0 failed")
extends SceneTree

const WORLD_SCENE := "res://src/world/World.tscn"
const TEST_SAVE := "user://test_ignis_save.json"
const SLIME_SCRIPT := "res://src/enemies/Slime.gd"
const CINDER_SCRIPT := "res://src/enemies/Cinder.gd"
const FPS := 60.0
const SCROLL_WAIT := 55
const WARP_WAIT := 40
const PULL_WAIT := 60
const BOLT_WAIT := 40                    # frames for an ice bolt to fly its whole way
const CRUST_WAIT := 400                  # frames > IceBolt.CRUST_TIME (6 s)
const TILE := 16.0
const AREA_BUILDER := "res://src/world/AreaBuilder.gd"   # loaded, never named: it pulls in autoload users
const ATLAS_JSON := "res://assets/tiles/overworld_light.json"

var _gs
var _w
var _p
var _passed := 0
var _failed := 0
var _ab


func _initialize() -> void:
	_gs = root.get_node("GameState")
	_ab = load(AREA_BUILDER)
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
	await _t_lava_river()
	await _t_lava_burns()
	await _t_ice_crust()
	await _t_crust_thaws_under_joe()
	await _t_ice_freezes_enemies()
	await _t_cinder()
	await _t_forge_islet()
	await _t_forge_channel()
	await _t_magma_wyrm()
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


# The terrain flag of an area cell right now ("lava", "pit", ...).
func _flag(area: String, cell: Array, flag: String) -> bool:
	return _ab.flag_at(self, _w.origin_of(area) + (Vector2(float(cell[0]), float(cell[1])) + Vector2(0.5, 0.5)) * TILE, flag)


func _use(item: String, facing: Vector2i, wait: int) -> void:
	_gs.give_item(item)
	_gs.equip(item)
	_gs.add_magic(_gs.MAX_MAGIC)
	_p.facing = facing
	await _tap("item")
	await _frames(wait)


# Walk in `dir` until Joe's cell is `target` (or the step budget runs out).
func _walk_to(target: Vector2i, dir: Vector2, max_frames: int = 180) -> void:
	_p._input_override = dir
	for i in max_frames:
		await _frames(1)
		if _cell() == target or _p.is_falling():
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
	var d: Dictionary = _w.dungeons.get("d5", {})
	_check("the Ignis Forge holds the second crystal", int(d.get("crystal", -1)) == 1 and not d.has("seal")
			and String(d.get("entrance", "")) == "d5_entrance", str(d))
	_check("the Cinder Barrens is a Dark World-only land east of Ash Lake", _w.is_dark("dw_cinder_barrens")
			and _w.origin_of("dw_cinder_barrens") == Vector2(72, 14) * TILE)
	_check("the ice rod is a Y-item that costs magic", _gs.ITEM_ORDER.has("ice_rod") and ItemDB.KINDS.has("ice_rod")
			and String(ItemDB.USES.get("ice_rod", "")) == "magic")
	var cells: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ATLAS_JSON))["cells"]
	var lava: Dictionary = cells.get("lava_0_0", {})
	_check("lava is a pit Joe falls into, low for the grapple, and freezable; crust is plain ground",
			bool(lava.get("pit", false)) and bool(lava.get("low", false)) and bool(lava.get("lava", false))
			and not bool(cells["crust"].get("pit", false)) and not bool(cells["crust"]["solid"]))


func _t_way_in() -> void:
	await _go("dw_east_lake", [22, 13], Vector2i.RIGHT)
	_p._input_override = Vector2.RIGHT
	await _frames(SCROLL_WAIT)
	_p._input_override = Vector2.ZERO
	_check("Ash Lake's shore path runs east into the Cinder Barrens", _w.current_id() == "dw_cinder_barrens",
			_w.current_id())
	_check("its lava cells are pits, low and lava", _flag("dw_cinder_barrens", [6, 13], "pit")
			and _flag("dw_cinder_barrens", [6, 13], "low") and _flag("dw_cinder_barrens", [6, 13], "lava"))
	var door: Array = _w.areas["dw_cinder_barrens"]["doors"]
	_check("the barrens' door leads into the forge", door.size() == 1 and String(door[0]["to"]) == "d5_entrance")


func _t_lava_river() -> void:
	await _go("dw_cinder_barrens", [3, 13], Vector2i.RIGHT)
	await _use("grapple", Vector2i.RIGHT, PULL_WAIT)
	_check("the grapple crosses the lava river by its hook post", _cell() == Vector2i(9, 13), str(_cell()))
	await _go("dw_cinder_barrens", [9, 10], Vector2i.LEFT)
	await _use("grapple", Vector2i.LEFT, PULL_WAIT)
	_check("...and the west post brings Joe back", _cell() == Vector2i(3, 10), str(_cell()))


func _t_lava_burns() -> void:
	await _go("dw_cinder_barrens", [3, 13], Vector2i.RIGHT)
	var hp: int = _p.health.current_health
	var falls: int = _w.falls
	await _walk_to(Vector2i(5, 13), Vector2.RIGHT, 60)
	await _frames(int(FPS * 1.2))
	_check("walking into lava burns: a heart lost and Joe back at the entry", _w.falls == falls + 1
			and _p.health.current_health < hp and _cell().x <= 3, "%d %s" % [_p.health.current_health, str(_cell())])
	_p.health.heal(_p.health.max_health)


func _t_ice_crust() -> void:
	await _go("dw_cinder_barrens", [15, 16], Vector2i.DOWN)
	_check("the islet is cut off by lava", _flag("dw_cinder_barrens", [15, 17], "lava"))
	var magic: int = _gs.MAX_MAGIC
	await _use("ice_rod", Vector2i.DOWN, 3)
	_check("an ice bolt costs 4 magic", _gs.magic == magic - ItemDB.ICE_ROD_MAGIC, str(_gs.magic))
	await _frames(BOLT_WAIT)
	var crust := not _flag("dw_cinder_barrens", [15, 17], "lava") and not _flag("dw_cinder_barrens", [15, 17], "pit") \
			and not _flag("dw_cinder_barrens", [15, 19], "lava")
	_check("the bolt freezes the lava it flies over into crust", crust)
	var pieces: int = _gs.heart_pieces
	await _walk_to(Vector2i(15, 21), Vector2.DOWN)
	await _frames(6)
	await _finish()
	_check("Joe walks over the crust to the islet's piece of heart", not _p.is_falling() and _w.falls == 1
			and _gs.heart_pieces == pieces + 1, "%s %d" % [str(_cell()), _gs.heart_pieces])
	await _frames(CRUST_WAIT)
	_check("the crust melts back into lava", _flag("dw_cinder_barrens", [15, 18], "lava"))


func _t_crust_thaws_under_joe() -> void:
	await _go("dw_cinder_barrens", [15, 16], Vector2i.DOWN)
	await _use("ice_rod", Vector2i.DOWN, BOLT_WAIT)
	await _walk_to(Vector2i(15, 18), Vector2.DOWN, 60)
	var falls: int = _w.falls
	await _frames(CRUST_WAIT)
	_check("standing on the crust when it melts drops Joe in", _w.falls == falls + 1, str(_w.falls))
	_p.health.heal(_p.health.max_health)


func _t_ice_freezes_enemies() -> void:
	await _go("d5_entrance", [11, 10], Vector2i.UP)
	_clear_enemies()
	var slime := _spawn(SLIME_SCRIPT, _w.cell_feet("d5_entrance", [11, 7]))
	await _frames(2)
	var hp: int = slime.health.current_health
	await _use("ice_rod", Vector2i.UP, 20)
	_check("an ice bolt freezes an enemy in a block of ice", slime._frozen_left > 0.0
			and slime.sprite.self_modulate == slime.ICE_TINT and slime.health.current_health == hp)
	await _frames(int(FPS * (slime.ICE_TIME + 0.3)))
	_check("it thaws after a while", slime._frozen_left <= 0.0 and slime.sprite.self_modulate == Color.WHITE)
	slime.queue_free()


func _t_cinder() -> void:
	await _go("d5_entrance", [11, 10], Vector2i.UP)
	_clear_enemies()
	var cinder := _spawn(CINDER_SCRIPT, _w.cell_feet("d5_entrance", [11, 7]))
	var dropped := false
	for i in 240:
		await _frames(1)
		if cinder.flames_left > 0:
			dropped = true
			break
	var flames := get_nodes_in_group("ground_flame")
	_check("a cinder leaves a flame where it lands", dropped and flames.size() >= 1)
	_check("the flame burns (an enemy hit box) and dies out", flames.size() >= 1 and flames[0].hit_box.damage > 0
			and flames[0].hit_box.collision_layer == 16)
	await _frames(int(FPS * 1.6))
	_check("...after a moment", get_nodes_in_group("ground_flame").size() <= 1)
	cinder.queue_free()


func _t_forge_islet() -> void:
	await _go("d5_west", [16, 6], Vector2i.LEFT)
	await _use("grapple", Vector2i.LEFT, PULL_WAIT)
	_check("in the west room the grapple reaches the lava islet", _cell() == Vector2i(10, 6), str(_cell()))
	var key_chest := false
	for c in _find("Chest"):
		key_chest = key_chest or (c.kind == "big_key" and c.global_position.distance_to(_w.cell_feet("d5_west", [10, 5])) < 12.0)
	_check("the big key's chest is right above", key_chest)
	await _go("d5_west", [11, 7], Vector2i.RIGHT)
	await _use("grapple", Vector2i.RIGHT, PULL_WAIT)
	_check("the east post brings Joe back", _cell() == Vector2i(16, 7), str(_cell()))


func _t_forge_channel() -> void:
	await _go("d5_east", [12, 6], Vector2i.RIGHT)
	_clear_enemies()
	await _use("ice_rod", Vector2i.RIGHT, 12)
	await _walk_to(Vector2i(17, 6), Vector2.RIGHT)
	_check("an ice path takes Joe across the east room's lava channel", _cell().x >= 16 and not _p.is_falling(),
			str(_cell()))
	_p.global_position = _w.cell_feet("d5_east", [19, 3])
	await _frames(10)
	_check("the switch beyond it clicks down", _gs.has_flag("switch:d5_east"))
	await _go("d5_hall", [11, 4], Vector2i.UP)
	var north_open := false
	for d in _find("Door"):
		if d.dir == "n":
			north_open = d.is_open
	_check("the hall's north shutter is open now", north_open)


func _t_magma_wyrm() -> void:
	await _go("d5_boss", [11, 10], Vector2i.UP)
	var wyrm := _boss()
	_check("the Magma Wyrm waits under its lava", wyrm != null and String(wyrm.get_script().get_global_name()) == "MagmaWyrm"
			and wyrm.state == "under" and not wyrm.sprite.visible)
	var up := false
	for i in 200:
		await _frames(1)
		if wyrm.state == "up":
			up = true
			break
	_check("it rises out of a lava cell", up and wyrm.surfacings == 1 and wyrm.spots.size() == 16
			and _flag("d5_boss", [int((wyrm.position.x - _w.origin_of("d5_boss").x) / TILE),
					int((wyrm.position.y - 6.0 - _w.origin_of("d5_boss").y) / TILE)], "lava"), str(wyrm.spots.size()))
	var hp: int = wyrm.health.current_health
	_hit(wyrm, 4)
	_check("out of the lava the sword only clanks off it", wyrm.health.current_health == hp)
	await _frames(int(FPS * 1.9))
	_check("it spits embers at Joe", wyrm.shots_fired >= 3, str(wyrm.shots_fired))
	var guard := 0
	while wyrm.state != "up" and wyrm.state != "rise" and guard < 400:
		guard += 1
		await _frames(1)
	_hit(wyrm, 0, "ice")
	_check("the ice rod freezes it above the lava", wyrm.is_frozen() and wyrm.freezes == 1)
	_hit(wyrm, 4)
	_check("frozen, it can be struck", wyrm.health.current_health == hp - 4)
	_hit(wyrm, 2)
	_hit(wyrm, 2)
	_check("after three hits it thaws and sinks", wyrm.state == "sink")
	guard = 0
	while is_instance_valid(wyrm) and not wyrm.is_dead() and guard < 3000:
		guard += 1
		if wyrm.state == "up" or wyrm.state == "rise":
			_hit(wyrm, 0, "ice")
		if wyrm.is_frozen():
			_hit(wyrm, 4)
		await _frames(1)
	_check("the Magma Wyrm falls", not is_instance_valid(wyrm) or wyrm.is_dead())
	await _frames(int(FPS * 1.5))
	await _collect_pickups()
	await _collect_pickups()
	await _frames(WARP_WAIT)
	_check("the Crystal of Ignis is Joe's and he is back in the barrens", _gs.crystals[1]
			and _w.current_id() == "dw_cinder_barrens", _w.current_id())
