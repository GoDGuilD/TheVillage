# File: ItemMenu.gd
# Description: The item menu (I / left shoulder) - ALttP's subscreen: a 5x2 grid of Y-item slots with a cursor that equips found items, Joe's equipment, the three family seals and the heart pieces toward the next container.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.1.0
class_name ItemMenu
extends CanvasLayer
## Slots follow GameState.ITEM_ORDER; an item shows once found (icons in assets/ui/items/, Phase 5).
## Confirm equips the item under the cursor; the menu closes with the inventory key, cancel or pause.

signal closed

const SLOT_TEX := preload("res://assets/ui/menu/slot.png")
const SWORD_TEX := preload("res://assets/ui/menu/icon_sword.png")
const SHIELD_TEX := preload("res://assets/ui/menu/icon_shield.png")
const SEAL_EMPTY_TEX := preload("res://assets/ui/menu/seal_empty.png")
const SEAL_FULL_TEX := preload("res://assets/ui/menu/seal_full.png")
const PIECES_TEX := preload("res://assets/ui/menu/heart_pieces.png")
const PIECES_FRAME := Vector2i(14, 13)
const PIECES_OFFSET := Vector2(176, 116)
const ITEM_ICON_DIR := "res://assets/ui/items/"
const PANEL_POS := Vector2(32, 26)
const PANEL_SIZE := Vector2(320, 164)
const COLUMNS := 5
const SLOT_STEP := 24.0
const GRID_OFFSET := Vector2(16, 26)
const HIGHLIGHT_GROW := 2.0              # the gold frame sits this far outside the selected slot
const NAME_OFFSET := Vector2(16, 80)
const EQUIP_OFFSET := Vector2(176, 26)
const EQUIP_STEP := 22.0
const SEALS_OFFSET := Vector2(16, 116)
const SEAL_STEP := 22.0
const CLOSE_ACTIONS := ["inventory", "ui_cancel", "pause"]
const NAV := {"ui_left": Vector2i.LEFT, "move_left": Vector2i.LEFT, "ui_right": Vector2i.RIGHT,
		"move_right": Vector2i.RIGHT, "ui_up": Vector2i.UP, "move_up": Vector2i.UP, "ui_down": Vector2i.DOWN,
		"move_down": Vector2i.DOWN}

var is_open := false
var selected := 0

var _root: Control
var _highlight: NinePatchRect
var _name: PixelText
var _icons: Array[Sprite2D] = []
var _seals: Array[Sprite2D] = []
var _pieces: Sprite2D


func _ready() -> void:
	layer = UiTheme.LAYER_MENU
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	add_child(_root)
	_root.add_child(UiTheme.overlay(UiTheme.DIM))
	_root.add_child(UiTheme.box(PANEL_POS, PANEL_SIZE))
	_label("ITEMS", PANEL_POS + GRID_OFFSET + Vector2(0, -14), UiTheme.GOLD)
	for i in GameState.ITEM_ORDER.size():
		var at := _slot_pos(i)
		_sprite(SLOT_TEX, at, false)
		_icons.append(_sprite(null, at + Vector2(SLOT_TEX.get_size()) / 2.0, true))
	_highlight = UiTheme.box(Vector2.ZERO, Vector2(SLOT_TEX.get_size()) + Vector2.ONE * HIGHLIGHT_GROW * 2.0,
			UiTheme.CAPTION_TEXTURE, UiTheme.CAPTION_BORDER)
	_highlight.draw_center = false
	_root.add_child(_highlight)
	_name = _label("", PANEL_POS + NAME_OFFSET, UiTheme.TEXT)
	_label("EQUIPMENT", PANEL_POS + EQUIP_OFFSET + Vector2(0, -14), UiTheme.GOLD)
	_sprite(SWORD_TEX, PANEL_POS + EQUIP_OFFSET, false)
	_label("SWORD", PANEL_POS + EQUIP_OFFSET + Vector2(22, 4), UiTheme.TEXT)
	_sprite(SHIELD_TEX, PANEL_POS + EQUIP_OFFSET + Vector2(0, EQUIP_STEP), false)
	_label("SHIELD", PANEL_POS + EQUIP_OFFSET + Vector2(22, 4 + EQUIP_STEP), UiTheme.TEXT)
	_label("FAMILY SEALS", PANEL_POS + SEALS_OFFSET + Vector2(0, -14), UiTheme.GOLD)
	for i in GameState.SEAL_COUNT:
		_seals.append(_sprite(SEAL_EMPTY_TEX, PANEL_POS + SEALS_OFFSET + Vector2(i * SEAL_STEP, 0), false))
	_label("HEART PIECES", PANEL_POS + PIECES_OFFSET + Vector2(0, -14), UiTheme.GOLD)
	_pieces = _sprite(null, PANEL_POS + PIECES_OFFSET, false)


func _label(text: String, pos: Vector2, color: Color) -> PixelText:
	var t := PixelText.make(text, pos, color)
	_root.add_child(t)
	return t


func _sprite(tex: Texture2D, pos: Vector2, centered: bool) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = centered
	s.position = pos
	_root.add_child(s)
	return s


func _slot_pos(i: int) -> Vector2:
	return PANEL_POS + GRID_OFFSET + Vector2((i % COLUMNS) * SLOT_STEP, (i / COLUMNS) * SLOT_STEP)


func open() -> void:
	is_open = true
	var at := GameState.ITEM_ORDER.find(GameState.equipped)
	selected = at if at >= 0 else 0
	_refresh()
	_root.visible = true
	get_tree().paused = true
	Audio.sfx("pause")


func close() -> void:
	if not is_open:
		return
	is_open = false
	_root.visible = false
	get_tree().paused = false
	Audio.sfx("menu_back")
	closed.emit()


func _refresh() -> void:
	for i in _icons.size():
		var item: String = GameState.ITEM_ORDER[i]
		var path := ITEM_ICON_DIR + item + ".png"
		_icons[i].texture = load(path) if GameState.has_item(item) and ResourceLoader.exists(path) else null
	for i in _seals.size():
		_seals[i].texture = SEAL_FULL_TEX if GameState.seals[i] else SEAL_EMPTY_TEX
	_highlight.position = _slot_pos(selected) - Vector2.ONE * HIGHLIGHT_GROW
	var pieces := AtlasTexture.new()
	pieces.atlas = PIECES_TEX
	pieces.region = Rect2(GameState.heart_pieces * PIECES_FRAME.x, 0, PIECES_FRAME.x, PIECES_FRAME.y)
	_pieces.texture = pieces
	var item_id: String = GameState.ITEM_ORDER[selected]
	_name.text = item_label(item_id)


# Name of a slot's item with its count where it has one ("BOMBS x5"), or "-" while not found.
func item_label(item_id: String) -> String:
	if not GameState.has_item(item_id):
		return "-"
	var label := ItemDB.display_name(item_id)
	if item_id == "bombs":
		label += " x%d" % GameState.bombs
	elif item_id == "bow":
		label += " x%d" % GameState.arrows
	return label


# Move the cursor by one slot (wraps inside the grid).
func move_cursor(dir: Vector2i) -> void:
	var n: int = GameState.ITEM_ORDER.size()
	var rows := int(ceil(float(n) / COLUMNS))
	var col := (selected % COLUMNS + dir.x + COLUMNS) % COLUMNS
	var row := (selected / COLUMNS + dir.y + rows) % rows
	selected = clampi(row * COLUMNS + col, 0, n - 1)
	Audio.sfx("menu_move")
	_refresh()


# Equip the item under the cursor if Joe has it.
func confirm() -> void:
	var item: String = GameState.ITEM_ORDER[selected]
	if GameState.has_item(item):
		GameState.equip(item)
		Audio.sfx("menu_select")


func _unhandled_input(event: InputEvent) -> void:
	if not is_open or event.is_echo():
		return
	for a in CLOSE_ACTIONS:
		if event.is_action_pressed(a):
			get_viewport().set_input_as_handled()
			close()
			return
	for a in NAV:
		if event.is_action_pressed(a):
			get_viewport().set_input_as_handled()
			move_cursor(NAV[a])
			return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		confirm()
