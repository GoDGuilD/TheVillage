# File: OptionsMenu.gd
# Description: The options screen (from the title screen and the pause menu) - music and sound volume bars, language, fullscreen and gamepad vibration; left/right or confirm change a row, and every change is applied at once and saved to the settings file.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-21
# Last edit date: 2026-10-21
# Version: 1.0.0
class_name OptionsMenu
extends CanvasLayer
## Rows are a MenuList (up/down/confirm/back); this layer adds left/right. The values (volume bars, ON/OFF, the
## language) are drawn beside the rows. Changing the language re-translates every text on screen (Loc.refresh).
## The menu that opened it stays inactive until `closed`.

signal closed

const ROW_MUSIC := 0
const ROW_SOUND := 1
const ROW_LANGUAGE := 2
const ROW_FULLSCREEN := 3
const ROW_VIBRATION := 4
const ROW_BACK := 5
const LABELS := ["MUSIC", "SOUND", "LANGUAGE", "FULLSCREEN", "VIBRATION", "BACK"]
const PANEL_SIZE := Vector2(236, 116)
const TITLE_Y := 9.0
const MENU_OFFSET := Vector2(16, 28)
const VALUE_X := 136.0                   # the value column (from the panel's left edge)
const BAR_SIZE := Vector2(6, 7)          # one step of a volume bar
const BAR_GAP := 2.0
const BAR_EMPTY := Color(0.35, 0.36, 0.53, 1.0)
const LEFT_ACTIONS := ["ui_left", "move_left"]
const RIGHT_ACTIONS := ["ui_right", "move_right"]

var is_open := false
var menu: MenuList
var changes := 0                         # values changed while open (tests)

var _root: Control
var _panel_pos := Vector2.ZERO
var _values: Array[Node] = []            # what is drawn in the value column (rebuilt on every change)


func _ready() -> void:
	layer = UiTheme.LAYER_MENU + 1           # over the pause menu / title that opened it
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	add_child(_root)
	_root.add_child(UiTheme.overlay(UiTheme.DIM))
	_panel_pos = ((UiTheme.VIEW - PANEL_SIZE) / 2.0).round()
	_root.add_child(UiTheme.box(_panel_pos, PANEL_SIZE))
	_root.add_child(PixelText.make("OPTIONS", _panel_pos + Vector2(PANEL_SIZE.x / 2.0, TITLE_Y), UiTheme.GOLD,
			PixelText.FONT_LARGE, PixelText.Align.CENTER))
	menu = MenuList.new()
	menu.position = _panel_pos + MENU_OFFSET
	_root.add_child(menu)
	var rows := []
	for l in LABELS:
		rows.append({"label": l, "enabled": true})
	menu.set_items(rows)
	menu.active = false
	menu.chosen.connect(_on_chosen)
	menu.cancelled.connect(close)


func open() -> void:
	is_open = true
	_root.visible = true
	menu.active = true
	menu.set_items(menu.items)
	_draw_values()


func close() -> void:
	if not is_open:
		return
	is_open = false
	menu.active = false
	_root.visible = false
	_audio().save_settings()
	closed.emit()


# Change the value of `row` by `step` (volumes go up and down; the other rows cycle either way).
func adjust(row: int, step: int) -> void:
	var audio := _audio()
	match row:
		ROW_MUSIC:
			audio.set_music_level(audio.music_level + step)
		ROW_SOUND:
			audio.set_sound_level(audio.sound_level + step)
		ROW_LANGUAGE:
			audio.set_language(Loc.next_language(Loc.language))
			Loc.refresh(get_tree())          # every open screen follows at once
		ROW_FULLSCREEN:
			audio.set_fullscreen(not audio.fullscreen)
		ROW_VIBRATION:
			audio.vibration = not audio.vibration
			if audio.vibration:
				Juice.rumble(0.3, 0.5, 0.2)       # a taste of it
		_:
			return
	changes += 1
	audio.sfx("menu_move")
	audio.save_settings()
	_draw_values()


func _on_chosen(index: int) -> void:
	if index == ROW_BACK:
		close()
	elif index in [ROW_LANGUAGE, ROW_FULLSCREEN, ROW_VIBRATION]:
		adjust(index, 1)


func _draw_values() -> void:
	for n in _values:
		n.queue_free()
	_values.clear()
	var audio := _audio()
	var x := _panel_pos.x + VALUE_X
	for row in LABELS.size():
		var y := menu.position.y + row * MenuList.ROW_STEP
		match row:
			ROW_MUSIC, ROW_SOUND:
				var level: int = audio.music_level if row == ROW_MUSIC else audio.sound_level
				for i in audio.LEVELS:
					var seg := ColorRect.new()
					seg.color = UiTheme.GOLD if i < level else BAR_EMPTY
					seg.size = BAR_SIZE
					seg.position = Vector2(x + i * (BAR_SIZE.x + BAR_GAP), y)
					seg.mouse_filter = Control.MOUSE_FILTER_IGNORE
					_root.add_child(seg)
					_values.append(seg)
			ROW_LANGUAGE:
				_value_text(String(Loc.LABELS[Loc.language]), Vector2(x, y))
			ROW_FULLSCREEN:
				_value_text("ON" if audio.fullscreen else "OFF", Vector2(x, y))
			ROW_VIBRATION:
				_value_text("ON" if audio.vibration else "OFF", Vector2(x, y))


func _value_text(text: String, pos: Vector2) -> void:
	var t := PixelText.make(text, pos, UiTheme.TEXT)
	_root.add_child(t)
	_values.append(t)


# The value shown for `row` right now, translated (tests).
func value_text(row: int) -> String:
	for n in _values:
		if n is PixelText and is_equal_approx(n.position.y, menu.position.y + row * MenuList.ROW_STEP):
			return n.text
	return ""


func _audio() -> Node:
	return get_node("/root/Audio")


func _unhandled_input(event: InputEvent) -> void:
	if not is_open or event.is_echo():
		return
	for a in LEFT_ACTIONS:
		if event.is_action_pressed(a):
			get_viewport().set_input_as_handled()
			adjust(menu.selected, -1)
			return
	for a in RIGHT_ACTIONS:
		if event.is_action_pressed(a):
			get_viewport().set_input_as_handled()
			adjust(menu.selected, 1)
			return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()
