# File: DialogueBox.gd
# Description: ALttP-style text box - word-wrapped pages typed out letter by letter with a blip, a speaker name plate, a bobbing "more" arrow; pauses the game while open.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
class_name DialogueBox
extends CanvasLayer
## open(pages, speaker, at_top) shows the text; confirm (interact / attack / ui_accept) first completes the page
## being typed, then turns to the next box, and closes after the last one (emitting `closed`).
## The box sits at the bottom of the screen unless Joe stands in the lower part, then at the top (ALttP).

signal closed

const MORE_TEX := "res://assets/ui/menu/more.png"
const MORE_FRAME := Vector2i(7, 6)
const MORE_FPS := 4.0
const BOX_SIZE := Vector2(296, 52)
const BOTTOM_Y := 156.0
const TOP_Y := 14.0
const PAD := Vector2(10, 8)
const LINES := 3
const LINE_STEP := 12.0
const CHARS_PER_SECOND := 45.0
const BLIP_EVERY := 3                    # letters between two text blips
const NAME_OFFSET := Vector2(8, -7)      # name plate relative to the box's top-left corner
const NAME_PAD := Vector2(6, 3)
const ADVANCE_ACTIONS := ["interact", "attack", "ui_accept"]

var is_open := false
var boxes: Array = []                    # each box = Array[String] of up to LINES wrapped lines
var box_index := 0
var shown_chars := 0.0                   # letters of the current box revealed so far

var _root: Control
var _lines: Array[PixelText] = []
var _more: AnimatedSprite2D
var _box_chars := 0                      # letters in the current box
var _last_blip := 0


func _ready() -> void:
	layer = UiTheme.LAYER_DIALOGUE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	add_child(_root)


# Show `pages` (each wraps itself and may fill several boxes). Pauses the tree until the last box is closed.
func open(pages: Array, speaker: String = "", at_top: bool = false) -> void:
	boxes = []
	var width := int(BOX_SIZE.x - PAD.x * 2.0)
	for page in pages:
		var lines := PixelText.wrap(String(page), width)
		for i in range(0, lines.size(), LINES):
			boxes.append(lines.slice(i, i + LINES))
	if boxes.is_empty():
		return
	_build(speaker, TOP_Y if at_top else BOTTOM_Y)
	is_open = true
	_root.visible = true
	get_tree().paused = true
	_show_box(0)


func _build(speaker: String, y: float) -> void:
	for c in _root.get_children():
		c.queue_free()
	_lines.clear()
	var pos := Vector2(roundf((UiTheme.VIEW.x - BOX_SIZE.x) / 2.0), y)
	_root.add_child(UiTheme.box(pos, BOX_SIZE))
	for i in LINES:
		var t := PixelText.make("", pos + PAD + Vector2(0, i * LINE_STEP), UiTheme.TEXT)
		_root.add_child(t)
		_lines.append(t)
	if speaker != "":
		var plate_size := Vector2(PixelText.measure(speaker), PixelText.line_height()) + NAME_PAD * 2.0
		_root.add_child(UiTheme.box(pos + NAME_OFFSET, plate_size, UiTheme.CAPTION_TEXTURE, UiTheme.CAPTION_BORDER))
		_root.add_child(PixelText.make(speaker, pos + NAME_OFFSET + NAME_PAD, UiTheme.GOLD))
	var frames := SpriteStrips.new_frames()
	SpriteStrips.add_strip(frames, "bob", MORE_TEX, MORE_FRAME, MORE_FPS, true)
	_more = AnimatedSprite2D.new()
	_more.sprite_frames = frames
	_more.centered = false
	_more.position = pos + BOX_SIZE - Vector2(MORE_FRAME) - Vector2(8, 5)
	_more.play("bob")
	_root.add_child(_more)


func _show_box(i: int) -> void:
	box_index = i
	shown_chars = 0.0
	_last_blip = 0
	_box_chars = 0
	for line in boxes[i]:
		_box_chars += String(line).length()
	_render()


func is_typing() -> bool:
	return is_open and int(shown_chars) < _box_chars


# Text of the current box as displayed so far (tests).
func visible_text() -> String:
	var parts: Array[String] = []
	for t in _lines:
		if t.text != "":
			parts.append(t.text)
	return " ".join(parts)


func _render() -> void:
	var left := int(shown_chars)
	var box: Array = boxes[box_index]
	for i in LINES:
		var full := String(box[i]) if i < box.size() else ""
		_lines[i].text = full.substr(0, clampi(left, 0, full.length()))
		left -= full.length()
	_more.visible = not is_typing() and box_index < boxes.size() - 1


func _process(delta: float) -> void:
	if not is_typing():
		return
	shown_chars = minf(shown_chars + CHARS_PER_SECOND * delta, float(_box_chars))
	if int(shown_chars) - _last_blip >= BLIP_EVERY:
		_last_blip = int(shown_chars)
		Audio.sfx("text_blip")
	_render()


# Confirm pressed: finish the typing, else next box, else close.
func advance() -> void:
	if not is_open:
		return
	if is_typing():
		shown_chars = float(_box_chars)
		_render()
	elif box_index < boxes.size() - 1:
		Audio.sfx("menu_move")
		_show_box(box_index + 1)
	else:
		close()


func close() -> void:
	is_open = false
	_root.visible = false
	get_tree().paused = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open or event.is_echo():
		return
	for a in ADVANCE_ACTIONS:
		if event.is_action_pressed(a):
			get_viewport().set_input_as_handled()
			advance()
			return
