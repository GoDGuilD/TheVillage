# File: test_items.gd
# Description: Headless scripted checks for Phase 5: item data, ammo and heart pieces, chests and the item-get, lantern and torches revealing a chest, small key and key block, bow and arrows, Janga's boomerang (flight, stun, fetching), bombs (fuse, blast, cracked rock, self-damage), Boni's shop, heart containers, HUD/menu read-outs and saving.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
# Run:  Godot_console --headless --fixed-fps 60 --path . -s tests/test_items.gd   (must end "0 failed")
extends SceneTree

const WORLD_SCENE := "res://src/world/World.tscn"
const SLIME_SCRIPT := "res://src/enemies/Slime.gd"
const PICKUP_SCRIPT := "res://src/world/Pickup.gd"
const TEST_SAVE := "user://test_items_save.json"
const FPS := 60.0

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
	_t_ammo_and_pieces()
	await _t_lantern_chest()
	await _t_chest_needs_facing_up()
	await _t_torches()
	await _t_key_and_block()
	await _t_bow()
	await _t_janga_boomerang()
	await _t_boomerang_flight()
	await _t_shop()
	await _t_bombs()
	await _t_heart_container()
	await _t_hud_and_menu()
	await _t_save_keeps_items()
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


# Read every box to the end (answering `answer` if a choice appears). Returns the texts seen.
func _finish(answer: int = 0) -> Array[String]:
	var seen: Array[String] = []
	var guard := 0
	while _w.dialogue.is_open and guard < 40:
		guard += 1
		_w.dialogue.advance()
		seen.append(_w.dialogue.visible_text())
		await process_frame
		if _w.dialogue.is_asking():
			_w.dialogue.choice_menu.selected = answer
			_w.dialogue.choice_menu.confirm()
			await process_frame
		else:
			_w.dialogue.advance()
			await process_frame
	await _frames(int(FPS * 0.25))
	return seen


func _find(cls_name: String) -> Array:
	var out := []
	for n in _w.current["actors"].get_children():
		if n.get_script() != null and String(n.get_script().get_global_name()) == cls_name:
			out.append(n)
	return out


func _slime_at(feet: Vector2) -> Node2D:
	var s: Node2D = load(SLIME_SCRIPT).new()
	s.position = feet
	s.player = _p
	_w.current["actors"].add_child(s)
	return s


# --- data and state --------------------------------------------------------------

func _t_data() -> void:
	var missing := []
	for kind in ItemDB.KINDS:
		if not DialogueData.has(ItemDB.text_key(kind)):
			missing.append(kind)
		if ItemDB.icon(kind) == null:
			missing.append(kind + " icon")
	_check("every item kind has its text and icon", missing.is_empty(), str(missing))
	var unknown := []
	for aid in _w.areas:
		for o in _w.areas[aid].get("objects", []):
			if o.has("item") and not ItemDB.has(String(o["item"])):
				unknown.append(o["item"])
		for wv in _w.areas[aid].get("wares", []):
			if not ItemDB.WARES.has(String(wv["ware"])):
				unknown.append(wv["ware"])
	_check("every chest and ware in the world is a known kind", unknown.is_empty(), str(unknown))
	for ware in ItemDB.WARES:
		if not DialogueData.has(String(ItemDB.WARES[ware]["text"])):
			unknown.append(ware)
	_check("every ware has its offer text", unknown.is_empty(), str(unknown))


func _t_ammo_and_pieces() -> void:
	_check("ammo is clamped to the bag", _gs.add_ammo("bombs", 99) == _gs.MAX_BOMBS and _gs.bombs == _gs.MAX_BOMBS)
	_check("using a bomb spends one", _gs.use_ammo("bombs") and _gs.bombs == _gs.MAX_BOMBS - 1)
	_gs.add_ammo("bombs", -99)
	_check("no ammo, no use", not _gs.use_ammo("bombs") and not _gs.use_ammo("arrows"))
	var done := [_gs.add_heart_piece(), _gs.add_heart_piece(), _gs.add_heart_piece(), _gs.add_heart_piece()]
	_check("the fourth heart piece completes a container", done == [false, false, false, true] and _gs.heart_pieces == 0)


# --- chests ----------------------------------------------------------------------

func _t_lantern_chest() -> void:
	await _go("joe_house", [10, 3], Vector2i.UP)
	var chests := _find("Chest")
	_check("Joe's house has a closed chest", chests.size() == 1 and not chests[0].opened)
	await _tap("interact")
	_check("opening it starts the item-get", _w.item_gets == 1 and _w.dialogue.is_open)
	_check("Joe holds the lantern over his head", _p.fsm.current_state == "hold" and _p.held_sprite != null)
	_check("the lantern is his and equipped (first item)", _gs.has_item("lantern") and _gs.equipped == "lantern")
	var seen := await _finish()
	_check("the text names the lantern", seen.size() > 0 and String(seen[0]).begins_with("You got the Lantern"), str(seen))
	_check("he lowers it when the box closes", _p.fsm.current_state == "idle" and _p.held_sprite == null)
	_check("the chest stays open", chests[0].opened and _gs.has_flag(chests[0].flag))
	await _tap("interact")
	_check("an open chest gives nothing more", _w.item_gets == 1 and not _w.dialogue.is_open)
	await _go("el_pueblo", [8, 9])
	await _go("joe_house", [10, 3], Vector2i.UP)
	_check("it is still open after leaving and coming back", _find("Chest")[0].opened)


func _t_chest_needs_facing_up() -> void:
	await _go("east_lake", [9, 7], Vector2i.RIGHT)
	await _tap("interact")
	_check("a chest does not open from the side", not _find("Chest")[0].opened and not _w.dialogue.is_open)


# --- lantern and torches ------------------------------------------------------------

func _t_torches() -> void:
	await _go("meadow_north", [28, 5], Vector2i.UP)
	var hidden: Array = _find("Chest")
	_check("the meadow chest is hidden at first", hidden.size() == 1 and hidden[0].concealed and not hidden[0].visible)
	var magic_before: int = _gs.magic
	await _tap("item")
	await _frames(5)
	var torches := _find("Torch")
	var lit := torches.filter(func(t: Node) -> bool: return t.lit).size()
	_check("the lantern lights the torch in front", lit == 1, str(lit))
	_check("the flame costs magic", _gs.magic == magic_before - ItemDB.LANTERN_MAGIC)
	_check("one torch is not enough", hidden[0].concealed)
	await _frames(int(FPS * 0.3))
	await _go("meadow_north", [39, 5], Vector2i.UP)
	# The area was rebuilt: torches went out. Light both, as a player would on one visit.
	await _tap("item")
	await _frames(int(FPS * 0.3))
	_p.global_position = _w.cell_feet("meadow_north", [28, 5])
	_p.facing = Vector2i.UP
	await _tap("item")
	await _frames(5)
	hidden = _find("Chest")
	_check("both torches burning reveal the chest", not hidden[0].concealed and hidden[0].visible)
	_p.global_position = _w.cell_feet("meadow_north", [34, 8])
	_p.facing = Vector2i.UP
	await _frames(15)                          # the lantern's use pose ends first
	await _tap("interact")
	_check("it holds a piece of heart", _gs.heart_pieces == 1, str(_gs.heart_pieces))
	await _finish()
	_gs.magic = 0
	await _tap("item")
	await _frames(3)
	_check("no magic, no flame", _gs.magic == 0 and _audio.played_recently("error"))
	_gs.add_magic(99)


# --- key and block -------------------------------------------------------------------

func _t_key_and_block() -> void:
	await _go("south_road", [41, 9], Vector2i.RIGHT)
	await _tap("interact")
	_w.dialogue.advance()
	_check("the key block is locked without a key", _w.dialogue.is_open and _find("KeyBlock").size() == 1)
	await _finish()
	await _go("east_lake", [10, 8], Vector2i.UP)
	await _tap("interact")
	await _finish()
	_check("the lake chest holds a small key", _gs.keys == 1)
	await _go("south_road", [41, 9], Vector2i.RIGHT)
	await _tap("interact")
	await _frames(3)
	_check("the key opens the block", _gs.keys == 0 and _find("KeyBlock").is_empty())
	await _go("el_pueblo", [8, 9])
	await _go("south_road", [41, 9], Vector2i.RIGHT)
	_check("the opened block stays open", _find("KeyBlock").is_empty())
	await _go("south_road", [44, 9], Vector2i.UP)
	await _tap("interact")
	await _finish()
	_check("the nook's chest holds the bow and ten arrows", _gs.has_item("bow") and _gs.arrows == 10)


# --- bow --------------------------------------------------------------------------

func _t_bow() -> void:
	_gs.equip("bow")
	await _go("el_pueblo", [8, 13], Vector2i.RIGHT)
	var slime := _slime_at(_w.cell_feet("el_pueblo", [12, 13]))
	slime.freeze(5.0)
	await _frames(2)
	await _tap("item")
	_check("shooting spends an arrow", _gs.arrows == 9 and _p.used_item == "bow")
	await _frames(20)
	_check("an arrow kills a slime (4 damage)", not is_instance_valid(slime) or slime.is_dead())
	await _go("el_pueblo", [8, 9], Vector2i.UP)
	await _tap("item")
	var arrows := get_nodes_in_group("arrow")
	await _frames(40)
	_check("an arrow sticks in a wall, then vanishes", arrows.size() == 1 and get_nodes_in_group("arrow").is_empty())
	var keep: int = _gs.arrows
	_gs.add_ammo("arrows", -99)
	await _tap("item")
	await _frames(2)
	_check("no arrows, no shot", get_nodes_in_group("arrow").is_empty() and _audio.played_recently("error"))
	_gs.add_ammo("arrows", keep)


# --- boomerang ----------------------------------------------------------------------

func _t_janga_boomerang() -> void:
	await _go("janga_house", [11, 5], Vector2i.UP)
	await _tap("interact")
	var first := await _finish()
	_check("the first talk is the greeting", not _gs.has_item("boomerang") and first.size() >= 3)
	await _tap("interact")
	var gifts: int = _w.item_gets
	var seen := await _finish()
	_check("the next talk hands over the boomerang", _gs.has_item("boomerang") and _w.item_gets == gifts + 1,
			str(seen))
	await _tap("interact")
	await _finish()
	_check("the gift is given only once", _w.item_gets == gifts + 1)


func _t_boomerang_flight() -> void:
	_gs.equip("boomerang")
	await _go("el_pueblo", [8, 13], Vector2i.RIGHT)
	var slime := _slime_at(_w.cell_feet("el_pueblo", [12, 13]))
	await _frames(3)
	await _tap("item")
	_check("the boomerang flies", get_nodes_in_group("boomerang").size() == 1)
	await _tap("item")
	await _frames(1)
	_check("only one boomerang at a time", get_nodes_in_group("boomerang").size() == 1)
	var stunned := false
	for i in 40:
		await _frames(1)
		if is_instance_valid(slime) and slime._frozen_left > 0.5:
			stunned = true
			break
	_check("it stuns an enemy without hurting it", stunned and slime.health.current_health == slime.health.max_health)
	await _frames(int(FPS * 1.5))
	_check("it comes back to Joe", get_nodes_in_group("boomerang").is_empty())
	if is_instance_valid(slime):
		slime.queue_free()
	var gem: Area2D = load(PICKUP_SCRIPT).new()
	gem.kind = "gem_red"
	gem.position = _w.cell_feet("el_pueblo", [12, 13]) + Vector2(0, -6)
	_w.current["actors"].add_child(gem)
	await _frames(3)
	var gems_before: int = _gs.gems
	_p.facing = Vector2i.RIGHT
	await _tap("item")
	await _frames(int(FPS * 1.6))
	_check("it brings back the gem it touched", _gs.gems == gems_before + 20, "%d -> %d" % [gems_before, _gs.gems])


# --- shop ------------------------------------------------------------------------------

func _t_shop() -> void:
	_gs.gems = 0
	_gs.add_gems(0)
	await _go("boni_shop", [5, 5], Vector2i.UP)
	await _tap("interact")
	_check("talking to a ware makes the offer", _w.dialogue.is_open and _w.dialogue.choices.size() == 2)
	var seen := await _finish(0)
	_check("without gems Boni refuses", not _gs.has_item("bombs") and seen.any(func(t: String) -> bool: return t.begins_with("Oh...")),
			str(seen))
	_gs.add_gems(200)
	_p.facing = Vector2i.UP
	await _tap("interact")
	await _finish(1)
	_check("answering NO buys nothing", _gs.gems == 200 and not _gs.has_item("bombs"))
	_p.facing = Vector2i.UP
	await _tap("interact")
	await _finish(0)
	_check("buying bombs: gems paid, bombs owned", _gs.gems == 180 and _gs.has_item("bombs") and _gs.bombs == 5)
	_p.facing = Vector2i.UP
	await _tap("interact")
	await _finish(0)
	_check("buying more bombs adds to the bag", _gs.gems == 160 and _gs.bombs == 10)
	_p.facing = Vector2i.UP
	await _tap("interact")
	seen = await _finish(0)
	_check("a full bag cannot take more", _gs.gems == 160 and _gs.bombs == 10)
	var pieces: int = _gs.heart_pieces
	await _go("boni_shop", [11, 5], Vector2i.UP)
	await _tap("interact")
	await _finish(0)
	_check("the heart piece sells once", _gs.gems == 60 and _gs.heart_pieces == pieces + 1
			and _find("ShopItem").size() == 2)
	await _go("el_pueblo", [8, 9])
	await _go("boni_shop", [11, 5], Vector2i.UP)
	_check("and is gone for good", _find("ShopItem").size() == 2)


# --- bombs --------------------------------------------------------------------------

func _t_bombs() -> void:
	_gs.equip("bombs")
	await _go("west_woods", [2, 22], Vector2i.DOWN)
	var rocks := _find("CrackedRock")
	_check("the woods hide a cracked rock", rocks.size() == 1)
	await _tap("item")
	_check("setting a bomb spends one", _gs.bombs == 9 and get_nodes_in_group("bomb").size() == 1)
	await _frames(15)
	await _tap("item")
	await _frames(15)
	await _tap("item")
	_check("at most two bombs tick at once", get_nodes_in_group("bomb").size() == 2 and _gs.bombs == 8)
	_p.global_position = _w.cell_feet("west_woods", [8, 22])
	await _frames(int(FPS * 1.9))
	_check("the bombs explode after the fuse", get_nodes_in_group("bomb").is_empty())
	_check("the blast breaks the cracked rock", _find("CrackedRock").is_empty()
			and _gs.has_flag(_w.object_flag("cracked_rock", "west_woods", [2, 24])))
	var pieces: int = _gs.heart_pieces
	_p.global_position = _w.cell_feet("west_woods", [2, 24])
	_p._input_override = Vector2.DOWN
	await _frames(20)
	_p._input_override = Vector2.ZERO
	_check("behind it lies a piece of heart", _w.dialogue.is_open and (_gs.heart_pieces == pieces + 1 or _gs.heart_pieces == 0))
	await _finish()
	# A bomb hurts enemies and Joe alike.
	await _go("el_pueblo", [8, 13], Vector2i.RIGHT)
	_p.hurt_box.set_deferred("monitoring", true)
	await _frames(2)
	var slime := _slime_at(_w.cell_feet("el_pueblo", [9, 13]))
	slime.freeze(5.0)
	var hp: int = _p.health.current_health
	await _tap("item")
	await _frames(int(FPS * 1.8))
	_check("the blast kills a slime beside it", not is_instance_valid(slime) or slime.is_dead())
	_check("and hurts Joe if he stands too close", _p.health.current_health < hp, "%d -> %d" % [hp, _p.health.current_health])
	_p.hurt_box.set_deferred("monitoring", false)
	_p.health.heal(99)
	await _frames(int(FPS * 1.2))


# --- hearts -------------------------------------------------------------------------

func _t_heart_container() -> void:
	await _go("el_pueblo", [8, 9])
	var before: int = _p.health.max_health
	_gs.heart_pieces = 3
	_w.item_get("heart_piece")
	var seen := await _finish()
	_check("a fourth piece adds a heart container", _p.health.max_health == before + 2 and _gs.heart_pieces == 0)
	_check("and the text says so", seen.any(func(t: String) -> bool: return t.begins_with("Your life grew")), str(seen))
	_check("the HUD shows the new heart, full", _w.hud.hearts_shown == "F".repeat((before + 2) / 2), _w.hud.hearts_shown)


# --- read-outs and saves ----------------------------------------------------------------

func _t_hud_and_menu() -> void:
	_check("the HUD shows bombs and arrows once owned", _w.hud.bombs_shown == _gs.bombs and _w.hud.arrows_shown == _gs.arrows)
	_check("the HUD item box shows the equipped item", _w.hud._item_icon.texture != null)
	_check("the item menu names counts", _w.item_menu.item_label("bombs") == "BOMBS x%d" % _gs.bombs)


func _t_save_keeps_items() -> void:
	await _go("el_pueblo", [8, 9])
	var max_hp: int = _p.health.max_health
	_check("save_game succeeds", _w.save_game())
	var bombs: int = _gs.bombs
	var arrows: int = _gs.arrows
	_w.queue_free()
	await process_frame
	_gs.reset()
	SaveGame.pending = SaveGame.read()
	_w = load(WORLD_SCENE).instantiate()
	root.add_child(_w)
	await process_frame
	_p = _w.player
	_p.hurt_box.set_deferred("monitoring", false)
	_check("items, ammo and the extra heart come back", _gs.has_item("boomerang") and _gs.has_item("bow")
			and _gs.bombs == bombs and _gs.arrows == arrows and _p.health.max_health == max_hp)
	await _go("joe_house", [10, 3], Vector2i.UP)
	_check("opened chests stay open after loading", _find("Chest")[0].opened)
	await _go("south_road", [41, 9], Vector2i.RIGHT)
	_check("opened key blocks stay open after loading", _find("KeyBlock").is_empty())
