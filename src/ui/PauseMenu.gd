# File: PauseMenu.gd
# Description: Pause menu (Esc / Start) - CONTINUE, SAVE GAME, OPTIONS, SAVE AND QUIT - over a dimmed, paused world; the World does the saving and quitting, the options screen opens on top.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-21
# Version: 1.1.0
class_name PauseMenu
extends CanvasLayer

signal save_requested
signal quit_requested
signal closed

const ITEM_CONTINUE := 0
const ITEM_SAVE := 1
const ITEM_OPTIONS := 2
const ITEM_SAVE_QUIT := 3
const PANEL_SIZE := Vector2(150, 97)
const TITLE_Y := 9.0
const MENU_OFFSET := Vector2(28, 28)
const NOTE_Y := 83.0

var is_open := false
var menu: MenuList
var options: OptionsMenu
var note: PixelText                      # "GAME SAVED" feedback line

var _root: Control


func _ready() -> void:
	layer = UiTheme.LAYER_MENU
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	add_child(_root)
	_root.add_child(UiTheme.overlay(UiTheme.DIM))
	var pos := ((UiTheme.VIEW - PANEL_SIZE) / 2.0).round()
	_root.add_child(UiTheme.box(pos, PANEL_SIZE))
	_root.add_child(PixelText.make("PAUSED", pos + Vector2(PANEL_SIZE.x / 2.0, TITLE_Y), UiTheme.GOLD,
			PixelText.FONT_LARGE, PixelText.Align.CENTER))
	menu = MenuList.new()
	menu.position = pos + MENU_OFFSET
	_root.add_child(menu)
	menu.set_items([{"label": "CONTINUE", "enabled": true}, {"label": "SAVE GAME", "enabled": true},
			{"label": "OPTIONS", "enabled": true}, {"label": "SAVE AND QUIT", "enabled": true}])
	menu.chosen.connect(_on_chosen)
	menu.cancelled.connect(close)
	note = PixelText.make("", pos + Vector2(PANEL_SIZE.x / 2.0, NOTE_Y), UiTheme.DIM_TEXT, PixelText.FONT_SMALL,
			PixelText.Align.CENTER)
	_root.add_child(note)
	options = OptionsMenu.new()
	add_child(options)
	options.closed.connect(func() -> void: menu.active = true)


func open() -> void:
	is_open = true
	note.text = ""
	menu.set_items(menu.items)
	_root.visible = true
	get_tree().paused = true
	Audio.sfx("pause")


func close() -> void:
	if not is_open:
		return
	is_open = false
	_root.visible = false
	get_tree().paused = false
	closed.emit()


func show_saved(ok: bool) -> void:
	note.text = "GAME SAVED" if ok else "SAVE FAILED"
	if ok:
		Audio.sfx("save_done")


func _on_chosen(index: int) -> void:
	match index:
		ITEM_CONTINUE:
			close()
		ITEM_SAVE:
			save_requested.emit()
		ITEM_OPTIONS:
			menu.active = false
			options.open()
		ITEM_SAVE_QUIT:
			quit_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
	if is_open and not options.is_open and event.is_action_pressed("pause") and not event.is_echo():
		get_viewport().set_input_as_handled()
		close()
