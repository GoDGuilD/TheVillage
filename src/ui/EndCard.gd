# File: EndCard.gd
# Description: The card shown at the end of an act - fades to black, shows the act's title and lines one by one, then waits for a confirm press and reports it.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-19
# Last edit date: 2026-10-19
# Version: 1.0.0
class_name EndCard
extends CanvasLayer
## Used for the end of Act 1 (Caver banishes Joe). Pauses the world; `finished` fires on the first confirm after
## every line is shown (the World then saves and returns to the title).

signal finished

const FADE_TIME := 1.0
const LINE_DELAY := 0.9                  # s between two lines appearing
const TITLE_Y := 56.0
const TITLE_SCALE := 2.0
const LINE_TOP := 96.0
const LINE_STEP := 14.0
const HINT_Y := 196.0
const CONFIRM_ACTIONS := ["ui_accept", "interact", "attack"]

var is_open := false
var ready_to_close := false
var lines_shown := 0

var _root: Control
var _black: ColorRect


func _ready() -> void:
	layer = UiTheme.LAYER_GAME_OVER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	add_child(_root)
	_black = UiTheme.overlay(UiTheme.BLACK)
	_root.add_child(_black)


func open(title: String, lines: Array) -> void:
	is_open = true
	ready_to_close = false
	lines_shown = 0
	_root.visible = true
	_black.modulate.a = 0.0
	get_tree().paused = true
	Audio.sfx("act_end")
	var tw := create_tween()
	tw.tween_property(_black, "modulate:a", 1.0, FADE_TIME)
	await tw.finished
	var t := PixelText.make(title, Vector2(UiTheme.VIEW.x / 2.0, TITLE_Y), UiTheme.GOLD, PixelText.FONT_LARGE,
			PixelText.Align.CENTER)
	t.scale = Vector2.ONE * TITLE_SCALE
	_root.add_child(t)
	for i in lines.size():
		await get_tree().create_timer(LINE_DELAY, true).timeout
		_root.add_child(PixelText.make(String(lines[i]), Vector2(UiTheme.VIEW.x / 2.0, LINE_TOP + i * LINE_STEP),
				UiTheme.TEXT, PixelText.FONT_LARGE, PixelText.Align.CENTER))
		lines_shown += 1
	_root.add_child(PixelText.make("PRESS ENTER", Vector2(UiTheme.VIEW.x / 2.0, HINT_Y), UiTheme.DIM_TEXT,
			PixelText.FONT_SMALL, PixelText.Align.CENTER))
	ready_to_close = true


func close() -> void:
	if not ready_to_close:
		return
	is_open = false
	get_tree().paused = false
	finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open or not ready_to_close or event.is_echo():
		return
	for a in CONFIRM_ACTIONS:
		if event.is_action_pressed(a):
			get_viewport().set_input_as_handled()
			close()
			return
