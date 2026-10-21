# File: test_polish.gd
# Description: Headless scripted checks for Phase 14 (polish, audio, localization): Loc and the Spanish tables, the fonts' Spanish letters, the Spanish dialogue (text only - the story's logic stays English), live re-translation, the audio buses, volume levels, loudness trims and the settings file, the music of each place and its crossfades, the options screen, gamepad bindings, controller hints and rumble.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-21
# Last edit date: 2026-10-21
# Version: 1.0.0
# Run:  Godot_console --headless --fixed-fps 60 --path . -s tests/test_polish.gd   (must end "0 failed")
extends SceneTree

const WORLD_SCENE := "res://src/world/World.tscn"
const TITLE_SCENE := "res://src/ui/TitleScreen.tscn"
const TEST_SAVE := "user://test_polish_save.json"
const TEST_SETTINGS := "user://test_polish_settings.cfg"
const MUSIC_DIR := "res://assets/audio/music/"
const FONT_DIR := "res://assets/ui/"
const SPANISH_LETTERS := "ÁÉÍÓÚÑÜáéíóúñü¡¿"
const ACTIONS := ["move_left", "move_right", "move_up", "move_down", "attack", "interact", "item", "dash", "map",
		"inventory", "pause", "ui_accept", "ui_cancel"]
const FPS := 60.0

var _gs
var _audio
var _juice
var _w
var _p
var _passed := 0
var _failed := 0


func _initialize() -> void:
	await process_frame                              # the autoloads' _ready (buses, players) runs first
	_gs = root.get_node("GameState")
	_audio = root.get_node("Audio")
	_juice = root.get_node("Juice")
	_gs.reset()
	_gs.drops_enabled = false
	SaveGame.path = TEST_SAVE
	SaveGame.delete()
	_audio.settings_path = TEST_SETTINGS
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))
	_audio.reset_settings()                          # English, default volumes - before anything is built
	await _run_all()


func _run_all() -> void:
	_t_defaults()
	_t_loc()
	_t_fonts()
	_t_dialogue_es()
	await _t_pixel_text()
	_t_levels()
	_t_settings_file()
	await _t_music_player()
	await _new_world()
	await _t_music_of_places()
	await _t_options()
	await _t_spanish_in_game()
	_t_bindings()
	await _t_gamepad_menus()
	_t_hints()
	await _t_rumble()
	await _t_title_screen()
	_audio.reset_settings()
	SaveGame.delete()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))
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


func _new_world() -> void:
	_w = load(WORLD_SCENE).instantiate()
	root.add_child(_w)
	await process_frame
	_p = _w.player
	_p.hurt_box.set_deferred("monitoring", false)


func _go(area: String, cell: Array) -> void:
	_w._enter(area, _w.cell_feet(area, cell), Vector2i.DOWN)
	await _frames(3)


func _press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame


func _pad_button(button: int) -> void:
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	var up := InputEventJoypadButton.new()
	up.button_index = button
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame


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


# The glyph of `ch` in a font atlas has ink.
func _has_glyph(font: String, ch: String) -> bool:
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FONT_DIR + "font_%s.json" % font))
	var img: Image = load(FONT_DIR + "font_%s.png" % font).get_image()
	var cell := Vector2i(int(meta["cell"][0]), int(meta["cell"][1]))
	var idx := ch.unicode_at(0) - int(meta["first_char"])
	var at := Vector2i((idx % int(meta["columns"])) * cell.x, (idx / int(meta["columns"])) * cell.y)
	if at.y + cell.y > img.get_height():
		return false
	return not img.get_region(Rect2i(at, cell)).get_used_rect().size == Vector2i.ZERO


# --- tests ---------------------------------------------------------------------

func _t_defaults() -> void:
	_check("a test run never reads the player's settings: English, default volumes", Loc.language == "en"
			and _audio.music_level == _audio.DEFAULT_LEVEL and _audio.sound_level == _audio.DEFAULT_LEVEL)
	_check("music and sound effects have their own buses", AudioServer.get_bus_index("Music") != -1
			and AudioServer.get_bus_index("SFX") != -1)


func _t_loc() -> void:
	_check("English passes through", Loc.t("NEW GAME") == "NEW GAME")
	Loc.set_language("es")
	_check("Spanish: exact entries", Loc.t("NEW GAME") == "NUEVA PARTIDA" and Loc.t("CAVER'S TOWER") == "TORRE DE CAVER",
			Loc.t("NEW GAME"))
	_check("Spanish: patterns keep their numbers", Loc.t("KEYS 3") == "LLAVES 3", Loc.t("KEYS 3"))
	_check("the text filled into a pattern is translated too", Loc.t("PRESS CIRCLE") == "PULSA CÍRCULO"
			and Loc.t("PRESS ENTER") == "PULSA ENTER", Loc.t("PRESS CIRCLE"))
	_check("unknown text stays as it is", Loc.t("Joe") == "Joe")
	_check("an unknown language falls back to English", Loc.set_language("xx") == "en" and Loc.t("QUIT") == "QUIT")


func _t_fonts() -> void:
	var missing := []
	for ch in SPANISH_LETTERS:
		if not _has_glyph("5x7", ch):
			missing.append("5x7 " + ch)
		if not _has_glyph("3x5", ch.to_upper() if ch.to_upper().length() == 1 else ch):
			missing.append("3x5 " + ch)
	_check("both fonts draw every Spanish letter and mark", missing.is_empty(), str(missing))
	_check("the ASCII glyphs are where they were", _has_glyph("5x7", "A") and _has_glyph("5x7", "z")
			and _has_glyph("3x5", "Z"))


func _t_dialogue_es() -> void:
	Loc.set_language("es")
	_check("in Spanish the signs speak Spanish", DialogueData.pages_for("sign_lake", _gs)[0].begins_with("LAGO DEL ESTE"))
	_check("and the speakers' names are translated", DialogueData.speaker("tato_echo") == "Eco de Tato"
			and DialogueData.speaker("shade_merchant") == "Sombra")
	_gs.set_flag("met_janga")
	var conv: Dictionary = DialogueData.conversation("janga", _gs)
	_check("a translated gift keeps the English logic (item, flag)", String(conv["gift"]) == "boomerang"
			and String(conv["pages"][0]).begins_with("¡Listo!"), str(conv["pages"]))
	Loc.set_language("en")
	_check("back in English the same keys speak English", DialogueData.speaker("tato_echo") == "Tato's echo"
			and DialogueData.pages_for("sign_lake", _gs)[0].begins_with("EAST LAKE"))
	_gs.reset()
	_gs.drops_enabled = false


func _t_pixel_text() -> void:
	await process_frame
	var t := PixelText.make("NEW GAME", Vector2.ZERO)
	var raw := PixelText.make("", Vector2.ZERO)
	raw.translate = false
	raw.text = "NEW GAME"
	root.add_child(t)
	root.add_child(raw)
	await process_frame
	Loc.set_language("es")
	Loc.refresh(self)
	_check("a language change re-translates the texts on screen", t.text == "NUEVA PARTIDA" and t.source == "NEW GAME",
			t.text)
	_check("texts that are already in the reader's language stay as they are", raw.text == "NEW GAME")
	Loc.set_language("en")
	Loc.refresh(self)
	_check("and back", t.text == "NEW GAME")
	t.free()
	raw.free()


func _t_levels() -> void:
	_audio.set_music_level(0)
	_check("music level 0 mutes the music bus", _audio.bus_muted("Music"))
	_audio.set_music_level(5)
	_check("level 5 is half volume", not _audio.bus_muted("Music")
			and is_equal_approx(_audio.bus_db("Music"), linear_to_db(0.5)), str(_audio.bus_db("Music")))
	_audio.set_sound_level(99)
	_check("levels are clamped to 0..10", _audio.sound_level == _audio.LEVELS)
	_check("the loudness trims are loaded (loud effects turned down, soft ones up)", float(_audio.sfx_trim.get("magic_jar", 0.0)) < 0.0
			and float(_audio.sfx_trim.get("splash", 0.0)) > 0.0, str(_audio.sfx_trim.size()))
	_audio.reset_settings()


func _t_settings_file() -> void:
	_audio.set_music_level(3)
	_audio.set_sound_level(6)
	_audio.set_language("es")
	_audio.vibration = false
	_check("settings save to their file", _audio.save_settings() and FileAccess.file_exists(TEST_SETTINGS))
	_audio.reset_settings()
	_audio.load_settings()
	_check("and load back", _audio.music_level == 3 and _audio.sound_level == 6 and Loc.language == "es"
			and not _audio.vibration)
	_audio.reset_settings()


func _t_music_player() -> void:
	var changes: int = _audio.music_changes
	_audio.play_music("valley")
	await _frames(5)
	_check("a track starts and loops", _audio.music_name == "valley" and _audio.is_music_playing()
			and _audio._music[_audio._music_now].stream.loop_mode == AudioStreamWAV.LOOP_FORWARD)
	_audio.play_music("valley")
	_check("asking for the same track does not restart it", _audio.music_changes == changes + 1)
	_audio.play_music("house")
	await _frames(int(FPS * (_audio.MUSIC_FADE + 0.2)))
	_check("a new track crossfades in and the old one stops", _audio.music_name == "house"
			and not _audio._music[1 - _audio._music_now].playing
			and is_equal_approx(_audio._music[_audio._music_now].volume_db, _audio.MUSIC_VOLUME_DB))
	var tracks := ["title", "valley", "house", "shrine", "dark_world", "dimension", "tower", "boss", "caver", "ending"]
	_check("all ten tracks exist", tracks.all(func(n: String) -> bool: return ResourceLoader.exists(MUSIC_DIR + n + ".wav")))
	_audio.stop_music()
	await _frames(int(FPS * (_audio.MUSIC_FADE + 0.2)))
	_check("the music can fade out", _audio.music_name == "" and not _audio.is_music_playing())


func _t_music_of_places() -> void:
	_check("Joe's house plays the house tune", _audio.music_name == "house", _audio.music_name)
	var want := {"el_pueblo": "valley", "dw_el_pueblo": "dark_world", "d1_entrance": "shrine",
			"d4_entrance": "dimension", "d8_entrance": "tower", "d1_boss": "boss", "d8_boss": "caver"}
	var wrong := []
	for aid in want:
		await _go(aid, [11, 10])
		while _w.dialogue.is_open:
			await _finish()
		if _audio.music_name != want[aid]:
			wrong.append("%s=%s" % [aid, _audio.music_name])
	_check("each place has its music (overworlds, dungeon families, bosses, Caver)", wrong.is_empty(), str(wrong))
	_gs.set_flag("boss:d1")
	await _go("d1_boss", [11, 10])
	_check("a beaten boss's room plays its dungeon's music", _audio.music_name == "shrine", _audio.music_name)
	_gs.reset()
	_gs.drops_enabled = false
	await _go("el_pueblo", [20, 12])


func _t_options() -> void:
	_w.pause_menu.open()
	await process_frame
	var pm = _w.pause_menu
	_check("the pause menu offers OPTIONS", pm.menu.label_of(pm.ITEM_OPTIONS) == "OPTIONS")
	pm.menu.selected = pm.ITEM_OPTIONS
	pm.menu.confirm()
	await process_frame
	var om = pm.options
	_check("it opens the options screen over the pause menu", om.is_open and not pm.menu.active)
	om.menu.selected = om.ROW_MUSIC
	var music: int = _audio.music_level
	await _press("ui_right")
	_check("right raises the music volume", _audio.music_level == music + 1)
	om.menu.selected = om.ROW_SOUND
	var sound: int = _audio.sound_level
	await _press("ui_left")
	_check("left lowers the sound volume", _audio.sound_level == sound - 1)
	_check("every change is saved at once", FileAccess.file_exists(TEST_SETTINGS))
	om.menu.selected = om.ROW_VIBRATION
	om.menu.confirm()
	var r: int = _juice.rumbles
	_juice.rumble(1.0, 1.0, 0.1)
	_check("vibration can be switched off (no rumble then)", not _audio.vibration and _juice.rumbles == r
			and om.value_text(om.ROW_VIBRATION) == "OFF")
	om.menu.confirm()
	_check("and on again", _audio.vibration)
	om.menu.selected = om.ROW_FULLSCREEN
	om.menu.confirm()
	_check("fullscreen toggles", _audio.fullscreen and om.value_text(om.ROW_FULLSCREEN) == "ON")
	om.menu.confirm()
	om.menu.selected = om.ROW_LANGUAGE
	om.menu.confirm()
	await process_frame
	_check("LANGUAGE switches to Spanish at once: the options and the pause menu behind them",
			Loc.language == "es" and om.value_text(om.ROW_LANGUAGE) == "ESPAÑOL"
			and pm.menu._labels[pm.ITEM_CONTINUE].text == "CONTINUAR" and om.menu._labels[om.ROW_BACK].text == "VOLVER",
			pm.menu._labels[0].text)
	await _press("ui_cancel")
	_check("back closes the options and the pause menu takes over again", not om.is_open and pm.menu.active and pm.is_open)
	var cfg := ConfigFile.new()
	_check("the language is in the settings file", cfg.load(TEST_SETTINGS) == OK
			and String(cfg.get_value("settings", "language", "")) == "es")
	pm.close()
	await process_frame


func _t_spanish_in_game() -> void:
	_check("the HUD speaks Spanish", _hud_has("- VIDA -"))
	await _go("east_lake", [4, 12])
	_w.say("sign_lake")
	await process_frame
	var seen := await _finish()
	_check("signs read in Spanish", seen.size() > 0 and String(seen[0]).begins_with("LAGO DEL ESTE"), str(seen))
	_w.hud.show_caption("EAST LAKE")
	await process_frame
	_check("area captions are translated", _w.hud._caption_text.text == "LAGO DEL ESTE")
	_audio.set_language("en")
	Loc.refresh(self)
	_check("and back to English", _hud_has("- LIFE -"))


func _hud_has(text: String) -> bool:
	for n in _w.hud.get_children():
		if n is PixelText and n.text == text:
			return true
	return false


func _t_bindings() -> void:
	var missing := []
	for a in ACTIONS:
		var pad := InputMap.action_get_events(a).filter(func(e: InputEvent) -> bool:
			return e is InputEventJoypadButton or e is InputEventJoypadMotion)
		if pad.is_empty():
			missing.append(a)
	_check("every action, menus included, has a gamepad binding", missing.is_empty(), str(missing))
	var dash := InputMap.action_get_events("dash").filter(func(e: InputEvent) -> bool: return e is InputEventJoypadButton)
	_check("dash is on both shoulder buttons", dash.size() == 2)
	var accept := InputMap.action_get_events("ui_accept").filter(func(e: InputEvent) -> bool:
		return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_B)
	var cancel := InputMap.action_get_events("ui_cancel").filter(func(e: InputEvent) -> bool:
		return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_A)
	_check("SNES layout: the right face button confirms, the bottom one goes back", accept.size() == 1 and cancel.size() == 1)


func _t_gamepad_menus() -> void:
	_w.pause_menu.open()
	await process_frame
	var pm = _w.pause_menu
	await _pad_button(JOY_BUTTON_DPAD_DOWN)
	_check("the d-pad moves a menu's cursor", pm.menu.selected == pm.ITEM_SAVE)
	await _pad_button(JOY_BUTTON_A)
	_check("the bottom button backs out of a menu", not pm.is_open)
	_w.pause_menu.open()
	await process_frame
	pm.menu.selected = pm.ITEM_OPTIONS
	await _pad_button(JOY_BUTTON_B)
	_check("the right button picks a row", pm.options.is_open)
	await _pad_button(JOY_BUTTON_A)
	pm.close()
	await process_frame


func _t_hints() -> void:
	var hints = _juice.hints
	hints.note(InputHints.KEYBOARD, "")
	_check("keyboard hints name the keys", InputHints.menu_hint() == "ARROWS + ENTER" and InputHints.press_hint() == "PRESS ENTER")
	hints.note(InputHints.GAMEPAD, "Xbox Wireless Controller")
	_check("an Xbox pad confirms with B", InputHints.press_hint() == "PRESS B" and InputHints.menu_hint() == "D-PAD + B")
	hints.note(InputHints.GAMEPAD, "PS5 Controller")
	_check("a PlayStation pad with circle", InputHints.confirm_label() == "CIRCLE")
	hints.note(InputHints.GAMEPAD, "Nintendo Switch Pro Controller")
	_check("a Nintendo pad with A", InputHints.confirm_label() == "A")
	hints.note(InputHints.KEYBOARD, "")


func _t_rumble() -> void:
	_audio.vibration = true
	var r: int = _juice.rumbles
	_p.hurt_box.set_deferred("monitoring", true)
	_p._iframes_left = 0.0
	_p._on_hurt(1, _p.global_position + Vector2(10, 0), Vector2.ZERO)
	_check("a hit on Joe rumbles the gamepad", _juice.rumbles == r + 1)
	_p.health.heal(_p.health.max_health)
	_p.hurt_box.set_deferred("monitoring", false)
	await _frames(int(FPS * 1.2))


func _t_title_screen() -> void:
	_w.queue_free()
	await process_frame
	var title = load(TITLE_SCENE).instantiate()
	root.add_child(title)
	await process_frame
	_check("the title plays its music and offers OPTIONS", _audio.music_name == "title"
			and title.menu.label_of(title.ITEM_OPTIONS) == "OPTIONS")
	_check("its hint names the keyboard keys", title.hint.text == "ARROWS + ENTER")
	_juice.hints.note(InputHints.GAMEPAD, "Xbox Wireless Controller")
	_check("and the gamepad's buttons once the pad is used", title.hint.text == "D-PAD + B", title.hint.text)
	_juice.hints.note(InputHints.KEYBOARD, "")
	title.menu.selected = title.ITEM_OPTIONS
	title.menu.confirm()
	await process_frame
	_check("OPTIONS opens the options screen from the title too", title.options.is_open and not title.menu.active)
	title.options.close()
	title.queue_free()
	await process_frame
