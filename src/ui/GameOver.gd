# File: GameOver.gd
# Description: Game Over screen - the view bleeds red then black, "GAME OVER" appears, and the player picks CONTINUE, SAVE AND CONTINUE or SAVE AND QUIT (the World carries the choice out).
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
class_name GameOver
extends CanvasLayer

signal picked(choice: int)

const CONTINUE := 0
const SAVE_CONTINUE := 1
const SAVE_QUIT := 2
const RED_TIME := 0.5
const BLACK_TIME := 0.6
const TITLE_Y := 64.0
const TITLE_SCALE := 2.0
const MENU_POS := Vector2(140, 104)

var is_open := false
var menu: MenuList

var _root: Control
var _red: ColorRect
var _black: ColorRect
var _title: PixelText


func _ready() -> void:
	layer = UiTheme.LAYER_GAME_OVER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	add_child(_root)
	_red = UiTheme.overlay(UiTheme.GAME_OVER_RED)
	_root.add_child(_red)
	_black = UiTheme.overlay(UiTheme.BLACK)
	_root.add_child(_black)
	_title = PixelText.make("GAME OVER", Vector2(UiTheme.VIEW.x / 2.0, TITLE_Y), UiTheme.LIFE_RED,
			PixelText.FONT_LARGE, PixelText.Align.CENTER)
	_title.scale = Vector2.ONE * TITLE_SCALE
	_root.add_child(_title)
	menu = MenuList.new()
	menu.position = MENU_POS
	_root.add_child(menu)
	menu.set_items([{"label": "CONTINUE", "enabled": true}, {"label": "SAVE AND CONTINUE", "enabled": true},
			{"label": "SAVE AND QUIT", "enabled": true}])
	menu.chosen.connect(_on_chosen)


# Run the red-to-black fade, then offer the choices. The world is paused underneath.
func open() -> void:
	is_open = true
	_root.visible = true
	_red.modulate.a = 0.0
	_black.modulate.a = 0.0
	_title.visible = false
	menu.visible = false
	menu.active = false
	get_tree().paused = true
	Audio.sfx("game_over")
	var tw := create_tween()
	tw.tween_property(_red, "modulate:a", 1.0, RED_TIME)
	tw.tween_property(_black, "modulate:a", 1.0, BLACK_TIME)
	await tw.finished
	if not is_open:
		return
	_title.visible = true
	menu.set_items(menu.items)
	menu.visible = true
	menu.active = true


func is_ready_to_choose() -> bool:
	return is_open and menu.active


func close() -> void:
	is_open = false
	_root.visible = false
	get_tree().paused = false


func _on_chosen(index: int) -> void:
	close()
	picked.emit(index)
