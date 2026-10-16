# File: MenuList.gd
# Description: Vertical menu of pixel-text rows with the animated gold cursor; emits chosen / cancelled and plays the menu sounds. Works while the tree is paused.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
class_name MenuList
extends Node2D
## Ported from Chapel of Dreams. Rows are {label: String, enabled: bool}; disabled rows are skipped by the cursor.
## Confirm = ui_accept or interact; cancel = ui_cancel.

signal chosen(index: int)
signal cancelled
signal moved(index: int)

const CURSOR_TEXTURE := "res://assets/ui/menu/cursor.png"
const CURSOR_FRAME := Vector2i(8, 8)
const CURSOR_FPS := 8.0
const ROW_STEP := 13.0
const LABEL_X := 12.0
const COLOR_NORMAL := UiTheme.TEXT
const COLOR_SELECTED := UiTheme.GOLD
const COLOR_DISABLED := UiTheme.DISABLED

var active := true
var selected := 0
var items: Array = []

var _labels: Array[PixelText] = []
var _cursor: AnimatedSprite2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var frames := SpriteStrips.new_frames()
	SpriteStrips.add_strip(frames, "spin", CURSOR_TEXTURE, CURSOR_FRAME, CURSOR_FPS, true)
	_cursor = AnimatedSprite2D.new()
	_cursor.sprite_frames = frames
	_cursor.centered = false
	_cursor.play("spin")
	add_child(_cursor)
	_refresh()


# Replace the rows and put the cursor on the first enabled one.
func set_items(new_items: Array) -> void:
	items = new_items
	selected = 0
	while selected < items.size() - 1 and not items[selected]["enabled"]:
		selected += 1
	for l in _labels:
		l.queue_free()
	_labels.clear()
	for i in items.size():
		var t := PixelText.make(items[i]["label"], Vector2(LABEL_X, i * ROW_STEP), COLOR_NORMAL)
		add_child(t)
		_labels.append(t)
	_refresh()
	moved.emit(selected)


func label_of(index: int) -> String:
	return String(items[index]["label"])


func _refresh() -> void:
	if _cursor == null:
		return
	_cursor.position = Vector2(0, selected * ROW_STEP)
	_cursor.visible = not items.is_empty()
	for i in _labels.size():
		_labels[i].color = COLOR_DISABLED if not items[i]["enabled"] else (COLOR_SELECTED if i == selected else COLOR_NORMAL)


func _move(step: int) -> void:
	if items.is_empty():
		return
	var n := items.size()
	for i in n:
		selected = (selected + step + n) % n
		if items[selected]["enabled"]:
			break
	Audio.sfx("menu_move")
	_refresh()
	moved.emit(selected)


# Pick the highlighted row (tests and the confirm keys).
func confirm() -> void:
	if items.is_empty() or not items[selected]["enabled"]:
		return
	Audio.sfx("menu_select")
	chosen.emit(selected)


func _unhandled_input(event: InputEvent) -> void:
	if not active or not is_visible_in_tree() or items.is_empty() or event.is_echo():
		return
	if event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		get_viewport().set_input_as_handled()
		_move(1)
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		get_viewport().set_input_as_handled()
		_move(-1)
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		confirm()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Audio.sfx("menu_back")
		cancelled.emit()
