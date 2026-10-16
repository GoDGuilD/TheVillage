# File: test_ui.gd
# Description: Headless scripted checks for Phase 4: text wrapping, dialogue data and flags, the HUD (hearts, magic, keys, gems, item box, area captions), talking to villagers and reading signs, the dialogue box, pause and item menus, saving and loading, and the title screen.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
# Run:  Godot_console --headless --fixed-fps 60 --path . -s tests/test_ui.gd   (must end "0 failed")
extends SceneTree

const WORLD_SCENE := "res://src/world/World.tscn"
const TITLE_SCENE := "res://src/ui/TitleScreen.tscn"
const TEST_SAVE := "user://test_village_save.json"
const FPS := 60.0
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
	_w = load(WORLD_SCENE).instantiate()
	root.add_child(_w)
	await process_frame
	_p = _w.player
	_p.hurt_box.set_deferred("monitoring", false)       # wandering enemies must not interfere
	await _run_all()


func _run_all() -> void:
	_t_wrap()
	_t_dialogue_data()
	await _t_hud()
	await _t_caption()
	await _t_talk_to_tato()
	await _t_close_does_not_reopen()
	await _t_sign_and_counter()
	await _t_lift_still_works()
	_t_box_side()
	await _t_pause_menu()
	await _t_item_menu()
	await _t_no_menu_during_dialogue()
	await _t_save_and_load()
	await _t_title()
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
	_w._enter(area, _w.cell_feet(area, cell), facing)
	_p.unfreeze()
	await _frames(3)


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


# Joe presses interact the way the player does (polled by his state machine; seen a frame later).
func _interact() -> void:
	Input.action_press("interact")
	await _frames(2)
	Input.action_release("interact")
	await _frames(1)


# Read a whole conversation: finish each box and turn the page until the box closes. Returns the texts seen.
func _read_all() -> Array[String]:
	var seen: Array[String] = []
	var guard := 0
	while _w.dialogue.is_open and guard < 40:
		guard += 1
		_w.dialogue.advance()                    # complete the typing
		seen.append(_w.dialogue.visible_text())
		await process_frame
		_w.dialogue.advance()                    # next box (or close)
		await process_frame
	return seen


# --- data ------------------------------------------------------------------------

func _t_wrap() -> void:
	var lines := PixelText.wrap("one two three four five six seven eight nine ten", 60)
	var widest := 0
	for l in lines:
		widest = maxi(widest, PixelText.measure(l))
	_check("word wrap keeps every line inside the width", lines.size() > 1 and widest <= 60, str(lines))
	var forced := PixelText.wrap("TITLE\nbody text", 200)
	_check("a newline forces a break", forced.size() == 2 and forced[0] == "TITLE", str(forced))


func _t_dialogue_data() -> void:
	_gs.flags = {}
	var first := DialogueData.pages_for("tato", _gs)
	var again := DialogueData.pages_for("tato", _gs)
	_check("Tato's first meeting lines differ from his later ones", first.size() == 3 and again.size() >= 1 and first[0] != again[0])
	_check("the first meeting sets its story flag", _gs.has_flag("met_tato"))
	_check("villagers have names, signs do not", DialogueData.speaker("boni") == "Boni" and DialogueData.speaker("sign_lake") == "")
	var missing := []
	for aid in _w.areas:
		for n in _w.areas[aid].get("npcs", []):
			if not DialogueData.has(String(n["id"])):
				missing.append(n["id"])
		for s in _w.areas[aid].get("signs", []):
			if not DialogueData.has(String(s["text"])):
				missing.append(s["text"])
	_check("every villager and sign in the world has text", missing.is_empty(), str(missing))
	_gs.flags = {}


# --- HUD ----------------------------------------------------------------------------

func _t_hud() -> void:
	var hud = _w.hud
	_check("three full hearts at the start", hud.hearts_shown == "FFF", hud.hearts_shown)
	_p.health.take_damage(1)
	await process_frame
	_check("a half-heart hit shows a half heart", hud.hearts_shown == "FFH", hud.hearts_shown)
	_p.health.heal(99)
	_check("magic meter starts full", hud.magic_shown == _gs.MAX_MAGIC)
	_gs.use_magic(8)
	_check("using magic lowers the meter", hud.magic_shown == _gs.MAX_MAGIC - 8)
	_check("spending more magic than Joe has fails", not _gs.use_magic(999) and _gs.magic == _gs.MAX_MAGIC - 8)
	_gs.add_magic(99)
	_check("the key counter hides at zero keys", not hud._key_icon.visible)
	_gs.add_keys(2)
	_check("a key shows the counter", hud._key_icon.visible and hud.keys_shown == 2)
	_gs.add_keys(-2)
	_gs.add_gems(42)
	_check("gems counter follows GameState", hud.gems_shown == 42)
	_gs.add_gems(-42)


func _t_caption() -> void:
	await _go("joe_house", [4, 6])
	_check("entering an area shows its name", _w.hud.caption_shown == "JOE'S HOUSE" and _w.hud.caption_visible(),
			_w.hud.caption_shown)
	await _frames(int(FPS * 2.6))
	_check("the caption fades away", not _w.hud.caption_visible())
	_p.global_position = _w.cell_feet("joe_house", [7, 8])
	_p._input_override = Vector2.DOWN
	await _frames(WARP_WAIT)
	_p._input_override = Vector2.ZERO
	_check("walking out shows the village's name", _w.hud.caption_shown == "EL PUEBLO", _w.hud.caption_shown)


# --- talking ------------------------------------------------------------------------

func _talker(area_id: String, id: String) -> Node2D:
	for n in get_nodes_in_group("talkable"):
		if n is Npc and n.npc_id == id:
			return n
	return null


func _t_talk_to_tato() -> void:
	_gs.flags = {}
	await _go("tato_house", [10, 6], Vector2i.UP)
	var tato := _talker("tato_house", "tato")
	_check("Tato stands in his house", tato != null)
	# Walk up to him so the body collision is what stops Joe.
	_p._input_override = Vector2.UP
	await _frames(20)
	_p._input_override = Vector2.ZERO
	_check("Tato's body blocks Joe", _p.global_position.y > tato.global_position.y + 4.0,
			"%s vs %s" % [_p.global_position, tato.global_position])
	await _interact()
	_check("interact facing Tato opens the dialogue box", _w.dialogue.is_open)
	_check("the world is paused while he talks", paused)
	_check("his name plate says Tato", _w.dialogue.boxes.size() > 0 and DialogueData.speaker("tato") == "Tato")
	_check("Tato turns to face Joe", tato.facing == Vector2i.DOWN)
	_check("the text types out letter by letter", _w.dialogue.is_typing())
	var before: Vector2 = _p.global_position
	_p._input_override = Vector2.LEFT
	await _frames(10)
	_p._input_override = Vector2.ZERO
	_check("Joe cannot walk while the box is open", _p.global_position == before)
	var seen := await _read_all()
	_check("the whole first meeting is read and the box closes",
			not _w.dialogue.is_open and seen.size() >= 3 and String(seen[0]).begins_with("Joe..."), str(seen.size()))
	_check("the world runs again afterwards", not paused)
	_check("meeting Tato is remembered", _gs.has_flag("met_tato"))
	await _frames(int(FPS * 0.3))
	await _interact()
	var again := await _read_all()
	_check("the next talk gives his later lines", again.size() >= 1 and String(again[0]).begins_with("Caver's guards"),
			str(again))


func _t_close_does_not_reopen() -> void:
	await _frames(int(FPS * 0.3))
	await _interact()
	var guard := 0
	while _w.dialogue.is_open and guard < 20:
		guard += 1
		if _w.dialogue.is_typing():
			_w.dialogue.advance()
			await process_frame
		else:
			await _press("interact")                # close with the same button that talks
	await _frames(3)
	_check("closing the box with interact does not start the talk again", not _w.dialogue.is_open)


func _t_sign_and_counter() -> void:
	await _go("el_pueblo", [20, 11], Vector2i.UP)
	await _interact()
	_check("reading the crossroads sign", _w.dialogue.is_open)
	_w.dialogue.advance()
	_check("the sign names the village", _w.dialogue.visible_text().begins_with("EL PUEBLO"), _w.dialogue.visible_text())
	await _read_all()
	await _go("boni_shop", [7, 5], Vector2i.UP)
	await _interact()
	_check("Boni answers across her counter", _w.dialogue.is_open)
	await _read_all()
	await _go("boni_shop", [7, 7], Vector2i.UP)
	await _interact()
	_check("too far from the counter, nobody answers", not _w.dialogue.is_open)


func _t_lift_still_works() -> void:
	await _go("tato_house", [3, 7], Vector2i.LEFT)
	await _interact()
	await _frames(15)
	_check("interact on a pot still lifts it", _p.carrying == "pot" and not _w.dialogue.is_open, _p.carrying)
	Input.action_press("interact")
	await _frames(2)
	Input.action_release("interact")
	await _frames(30)


func _t_box_side() -> void:
	_check("the box sits at the bottom when Joe is high on the screen", not _w.box_at_top(Vector2(0, 60)))
	_check("the box moves to the top when Joe is low on the screen", _w.box_at_top(Vector2(0, 170)))


# --- menus --------------------------------------------------------------------------

func _t_pause_menu() -> void:
	await _go("el_pueblo", [8, 9])
	await _press("pause")
	_check("Esc opens the pause menu", _w.pause_menu.is_open and paused)
	await _press("ui_down")
	_check("the cursor moves to SAVE GAME", _w.pause_menu.menu.selected == _w.pause_menu.ITEM_SAVE)
	await _press("ui_accept")
	_check("SAVE GAME writes the save file", SaveGame.has_save() and _w.pause_menu.note.text == "GAME SAVED")
	await _press("pause")
	_check("Esc again closes it", not _w.pause_menu.is_open and not paused)


func _t_item_menu() -> void:
	await _press("inventory")
	_check("I opens the item menu", _w.item_menu.is_open and paused)
	_check("nothing found yet: the slot reads '-'", _w.item_menu._name.text == "-")
	_w.item_menu.move_cursor(Vector2i.RIGHT)
	_check("the cursor moves right", _w.item_menu.selected == 1)
	_w.item_menu.move_cursor(Vector2i.DOWN)
	_check("and down a row", _w.item_menu.selected == 6)
	_gs.give_item("bow")
	_gs.equip("")
	_w.item_menu.move_cursor(Vector2i.UP)
	_w.item_menu.confirm()
	_check("confirm equips the found item under the cursor", _gs.equipped == "bow")
	_check("the HUD box shows what is equipped", _w.hud._item_icon != null)
	await _press("inventory")
	_check("I again closes the item menu", not _w.item_menu.is_open and not paused)
	_gs.items = {}
	_gs.equip("")


func _t_no_menu_during_dialogue() -> void:
	await _go("el_pueblo", [20, 11], Vector2i.UP)
	await _interact()
	await _press("pause")
	_check("Esc does not open the pause menu over a conversation", _w.dialogue.is_open and not _w.pause_menu.is_open)
	await _read_all()


# --- saving -------------------------------------------------------------------------

func _t_save_and_load() -> void:
	_gs.add_gems(37)
	_gs.set_flag("met_janga")
	_gs.seals[1] = true
	await _go("east_lake", [3, 13], Vector2i.RIGHT)
	_p.health.take_damage(3)
	var entry: Vector2 = _w.entry_point
	_check("save_game succeeds", _w.save_game())
	var data := SaveGame.read()
	_check("the save holds the area and the entry point", data.get("area") == "east_lake"
			and Vector2(data["pos"][0], data["pos"][1]) == entry)
	_check("the save holds hearts and the game state", int(data.get("hp", 0)) == 3
			and int(data["state"]["gems"]) == 37 and bool(data["state"]["flags"].get("met_janga", false)))
	# A fresh world started from that save (what the title's CONTINUE does).
	_w.queue_free()
	await process_frame
	_gs.reset()
	SaveGame.pending = SaveGame.read()
	_w = load(WORLD_SCENE).instantiate()
	root.add_child(_w)
	await process_frame
	_p = _w.player
	_p.hurt_box.set_deferred("monitoring", false)
	_check("loading starts in the saved area", _w.current_id() == "east_lake", _w.current_id())
	_check("Joe stands where he entered it", _p.global_position == entry, "%s vs %s" % [_p.global_position, entry])
	_check("his hearts are as saved", _p.health.current_health == 3 and _w.hud.hearts_shown == "FHE", _w.hud.hearts_shown)
	_check("gems, flags and seals come back", _gs.gems == 37 and _gs.has_flag("met_janga") and _gs.seals[1])
	_check("the pending save is consumed", SaveGame.pending.is_empty())
	var f := FileAccess.open(SaveGame.path, FileAccess.WRITE)
	f.store_string("{\"version\": 999}")
	f = null
	_check("a save from another version is ignored", SaveGame.read().is_empty())
	_gs.reset()


func _t_title() -> void:
	_w.queue_free()
	await process_frame
	SaveGame.delete()
	var t = load(TITLE_SCENE).instantiate()
	root.add_child(t)
	await process_frame
	_check("without a save CONTINUE is disabled", not t.menu.items[0]["enabled"] and t.menu.selected == 1)
	_check("the title backdrop is the village", t._backdrop.get_child_count() > 0)
	t.queue_free()
	await process_frame
	SaveGame.write({"version": SaveGame.VERSION, "area": "el_pueblo"})
	t = load(TITLE_SCENE).instantiate()
	root.add_child(t)
	await process_frame
	_check("with a save CONTINUE is offered first", t.menu.items[0]["enabled"] and t.menu.selected == 0)
	t.queue_free()
	await process_frame
