# File: test_silva.gd
# Description: Headless scripted checks for Phase 12 (Silva): the region's data and pegged way in, deep water (a wall without the flippers, swimming with them: slower, no sword, the far bank's piece of heart), the grove's pools, the mirror and water, snapvines (lunge, rooted), the Grove's pool-barred doorway, and the Thornheart (seeds, fire opens it, sword while open) with the fourth crystal.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-20
# Last edit date: 2026-10-20
# Version: 1.0.0
# Run:  Godot_console --headless --fixed-fps 60 --path . -s tests/test_silva.gd   (must end "0 failed")
extends SceneTree

const WORLD_SCENE := "res://src/world/World.tscn"
const TEST_SAVE := "user://test_silva_save.json"
const SNAPVINE_SCRIPT := "res://src/enemies/Snapvine.gd"
const FPS := 60.0
const SCROLL_WAIT := 55
const WARP_WAIT := 40
const TILE := 16.0
const LAYER_WATER := 512                 # AreaBuilder.LAYER_WATER

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
	await _t_water_without_flippers()
	await _t_swimming()
	await _t_mirror_and_water()
	await _t_grove_pools()
	await _t_snapvine()
	await _t_grove_doorway()
	await _t_thornheart()
	await _t_item_menu()
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


func _collect_pickups() -> void:
	for p in get_nodes_in_group("pickup"):
		_p.global_position = p.global_position
	await _frames(4)
	await _finish()
	await _frames(3)


# --- tests -------------------------------------------------------------------

func _t_data() -> void:
	var d: Dictionary = _w.dungeons.get("d7", {})
	_check("the Silva Grove holds the fourth crystal", int(d.get("crystal", -1)) == 3 and not d.has("seal")
			and String(d.get("entrance", "")) == "d7_entrance", str(d))
	_check("the Silva Tangle is a Dark World-only land west of the Thorn Woods", _w.is_dark("dw_silva_tangle")
			and _w.origin_of("dw_silva_tangle") == Vector2(-48, 14) * TILE)
	_check("the flippers are gear, not a Y-item", ItemDB.KINDS.has("flippers") and not _gs.ITEM_ORDER.has("flippers"))


func _t_way_in() -> void:
	await _go("dw_west_woods", [5, 13], Vector2i.LEFT)
	_clear_enemies()
	await _walk_to(Vector2i(1, 13), Vector2.LEFT, 60)
	_check("a row of pegs bars the Thorn Woods' west edge", _w.current_id() == "dw_west_woods" and _cell().x >= 4,
			str(_cell()))
	await _use("hammer", Vector2i.LEFT, 20)
	_p._input_override = Vector2.LEFT
	await _frames(SCROLL_WAIT + 30)
	_p._input_override = Vector2.ZERO
	await _settle()
	_check("with a peg pounded flat the path runs west into the Silva Tangle", _w.current_id() == "dw_silva_tangle",
			_w.current_id())
	var door: Array = _w.areas["dw_silva_tangle"]["doors"]
	_check("the Tangle's door leads into the Grove", door.size() == 1 and String(door[0]["to"]) == "d7_entrance")


func _t_water_without_flippers() -> void:
	_gs.items.erase("flippers")
	await _go("dw_silva_tangle", [13, 6], Vector2i.LEFT)
	_clear_enemies()
	await _walk_to(Vector2i(7, 6), Vector2.LEFT, 90)
	_check("without the flippers the river stops Joe at its bank", _cell().x >= 11 and not _p.is_swimming(), str(_cell()))


func _t_swimming() -> void:
	_w.grant("flippers")
	await _go("dw_silva_tangle", [13, 6], Vector2i.LEFT)
	_clear_enemies()
	var history_before: int = _audio.history.size()
	await _walk_to(Vector2i(9, 6), Vector2.LEFT, 90)
	_check("with the flippers he walks into the river and swims", _p.is_swimming() and _cell() == Vector2i(9, 6),
			str(_cell()))
	_check("...with a splash", _audio.history.slice(history_before).has("splash"))
	_check("...his shadow hidden", not _p.get_node("Shadow").visible)
	await _tap("attack")
	await _frames(2)
	_check("no sword while swimming", _p.is_swimming() and not _p.sword.monitorable)
	var before: Vector2 = _p.global_position
	_p._input_override = Vector2.DOWN
	await _frames(30)
	_p._input_override = Vector2.ZERO
	var speed: float = _p.global_position.distance_to(before) / 0.5
	_check("swimming is slower than walking", speed > 40.0 and speed < 70.0, "%.1f px/s" % speed)
	await _walk_to(Vector2i(6, 6), Vector2.LEFT, 90)
	_check("on the far bank he walks again", not _p.is_swimming() and _cell().x <= 7 and _p.get_node("Shadow").visible,
			str(_cell()))
	var pieces: int = _gs.heart_pieces
	_p.global_position = _w.cell_feet("dw_silva_tangle", [4, 14])
	await _frames(6)
	await _finish()
	_check("the far bank's piece of heart is his", _gs.heart_pieces == (pieces + 1) % 4, str(_gs.heart_pieces))


func _t_mirror_and_water() -> void:
	await _go("dw_silva_tangle", [12, 6], Vector2i.LEFT)
	var water: Vector2 = _w.cell_feet("dw_silva_tangle", [9, 6])
	_gs.items.erase("flippers")
	var blocked: bool = _w._solid_at(water)
	_w.grant("flippers")
	_check("a mirror warp may not land in deep water, unless he can swim", blocked and not _w._solid_at(water))
	_p.facing = Vector2i.LEFT
	_gs.give_item("moon_mirror")
	_gs.equip("moon_mirror")
	await _tap("item")
	await _frames(6)
	_check("the Moon Mirror finds no twin for the Tangle", _w.dialogue.is_open and _w.current_id() == "dw_silva_tangle")
	await _finish()


func _t_grove_pools() -> void:
	await _go("d7_entrance", [11, 10], Vector2i.UP)
	var tiles: TileMapLayer = _w.current["tiles"]
	var cell := Vector2i(3, 3)
	var coords := tiles.get_cell_atlas_coords(cell)
	var td := tiles.get_cell_tile_data(cell)
	_check("a pool in the Grove is painted with the grove's water and swims like a river",
			coords.x >= 9 and coords.x <= 11 and coords.y >= 4 and coords.y <= 6 and bool(td.get_custom_data("water")),
			str(coords))


func _t_snapvine() -> void:
	await _go("d7_entrance", [11, 10], Vector2i.UP)
	_clear_enemies()
	var vine := _spawn(SNAPVINE_SCRIPT, _w.cell_feet("d7_entrance", [11, 8]))
	var home: Vector2 = vine.global_position
	await process_frame
	_check("deep water is a wall to enemies", vine.collision_mask & LAYER_WATER != 0)
	await _frames(int(FPS * (vine.WIND_TIME + vine.LUNGE_TIME)) + 4)
	_check("a snapvine lunges at Joe when he comes near", vine.lunges == 1 and vine.head.y > 20.0, str(vine.head))
	await _frames(int(FPS * (vine.HOLD_TIME + vine.RETURN_TIME)) + 4)
	_check("...and pulls its head back", vine.state == "wait" and vine.head == Vector2.ZERO)
	var hp: int = vine.health.current_health
	_hit(vine, 2)
	await _frames(10)
	_check("a hit hurts it but never moves its root", vine.health.current_health == hp - 2
			and vine.global_position.distance_to(home) < 0.5)
	vine.queue_free()


func _t_grove_doorway() -> void:
	_gs.items.erase("flippers")
	await _go("d7_hall", [11, 7], Vector2i.UP)
	_clear_enemies()
	await _walk_to(Vector2i(11, 1), Vector2.UP, 60)
	_check("a pool bars the hall's north doorway", _w.current_id() == "d7_hall" and _cell().y >= 5, str(_cell()))
	await _go("d7_west", [4, 8], Vector2i.UP)
	_clear_enemies()
	await _walk_to(Vector2i(4, 4), Vector2.UP, 60)
	_check("pegs fence the big key's corner", _cell().y >= 7, str(_cell()))
	_w.grant("flippers")
	await _go("d7_hall", [11, 7], Vector2i.UP)
	_clear_enemies()
	_p._input_override = Vector2.UP
	for i in 300:
		await _frames(1)
		if _w.current_id() == "d7_boss":
			break
	_p._input_override = Vector2.ZERO
	await _settle()
	_check("with the flippers Joe swims across to the boss", _w.current_id() == "d7_boss", _w.current_id())


func _t_thornheart() -> void:
	await _go("d7_boss", [8, 6], Vector2i.RIGHT)
	var heart := _boss()
	_check("the Thornheart waits on its island", heart != null
			and String(heart.get_script().get_global_name()) == "Thornheart")
	var hp: int = heart.health.current_health
	_hit(heart, 4)
	_check("its thorns turn the sword", heart.health.current_health == hp and not heart.is_open())
	await _frames(int(FPS * (heart.SEED_TIME + 0.2)))
	_check("it spits a fan of seeds at Joe", heart.volleys >= 1 and heart.shots_fired >= heart.SEEDS,
			str(heart.shots_fired))
	for i in int(FPS * 4.5):
		await _frames(1)
		if heart.volleys >= heart.RING_EVERY:
			break
	_check("every third volley is a ring", heart.shots_fired >= heart.SEEDS * (heart.RING_EVERY - 1) + heart.RING_SEEDS,
			str(heart.shots_fired))
	_hit(heart, 4, "fire")
	_check("the fire rod burns its thorns back: it opens", heart.is_open() and heart.blooms == 1
			and heart.health.current_health == hp)
	_hit(heart, 4)
	_check("open, the sword reaches its heart", heart.health.current_health == hp - 4)
	_hit(heart, 2)
	_hit(heart, 2)
	_check("after three hits it closes again", not heart.is_open())
	var guard := 0
	while is_instance_valid(heart) and not heart.is_dead() and guard < 40:
		guard += 1
		if not heart.is_open():
			_hit(heart, 4, "fire")
		_hit(heart, 4)
		await _frames(2)
	_check("the Thornheart falls", not is_instance_valid(heart) or heart.is_dead())
	await _frames(int(FPS * 1.5))
	await _collect_pickups()
	await _collect_pickups()
	await _frames(WARP_WAIT)
	_check("the Crystal of Silva is Joe's and he is back in the Tangle", _gs.crystals[3]
			and _w.current_id() == "dw_silva_tangle", _w.current_id())


func _t_item_menu() -> void:
	_w.grant("flippers")
	_w.item_menu.open()
	await process_frame
	_check("the item menu shows the flippers with the gear", _w.item_menu._flippers_icon.visible
			and _w.item_menu._flippers_label.visible)
	_check("the item menu's crystal sockets fill as crystals are found", _gs.crystals[3]
			and _w.item_menu._crystals[3].texture == _w.item_menu.CRYSTAL_FULL_TEX)
	_w.item_menu.close()
	await process_frame
