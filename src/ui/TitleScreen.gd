# File: TitleScreen.gd
# Description: Title screen - "THE VILLAGE" over a slow pan across El Pueblo, with CONTINUE (when a save exists), NEW GAME and QUIT.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-20
# Version: 1.1.0
extends Node2D
## The backdrop is the real village, painted by AreaBuilder from its generated area (no enemies), so the title
## always matches the game. CONTINUE hands the save to the World through SaveGame.pending.

const WORLD_SCENE := "res://src/world/World.tscn"
const BACKDROP_AREA := "res://src/world/areas/el_pueblo.json"
const LOGO_TEXTURE := preload("res://assets/ui/title_logo.png")
# Animated GoDGuilD logo (src/ui/GgLogo.gd + assets/ui/gg_logo/, copies from the 2026 logo package),
# small in the bottom-right corner. Linear filtering: the project default (nearest) would alias the
# downscaled chrome art.
const GG_LOGO := preload("res://src/ui/GgLogo.gd")
const GG_LOGO_DIR := "res://assets/ui/gg_logo/"
const GG_LOGO_SIZE := Vector2(52, 42)          # keeps the logo art's 1920x1560 aspect
const GG_LOGO_MARGIN := 5.0
const TILE := 16.0
const LOGO_Y := 34.0
const SUBTITLE_Y := 76.0
const SUBTITLE := "A STORY BEFORE THE CHAPEL"
const MENU_POS := Vector2(160, 106)
const HINT_Y := 202.0
const PAN_SPEED := 6.0                   # px per second the backdrop drifts
const PAN_START := Vector2(2, 1)         # tiles: top-left of the view at the start of the pan
const ITEM_CONTINUE := 0
const ITEM_NEW := 1
const ITEM_QUIT := 2

var menu: MenuList
var started := ""                        # "continue" / "new" once a choice was made (tests)

var _backdrop: Node2D
var _pan_min := 0.0
var _pan_max := 0.0
var _pan_dir := 1.0


func _ready() -> void:
	get_tree().paused = false
	_build_backdrop()
	var shade := UiTheme.overlay(UiTheme.TITLE_SHADE)
	var ui := CanvasLayer.new()
	ui.layer = UiTheme.LAYER_MENU
	add_child(ui)
	ui.add_child(shade)
	var logo := Sprite2D.new()
	logo.texture = LOGO_TEXTURE
	logo.centered = false
	logo.position = Vector2(roundf((UiTheme.VIEW.x - LOGO_TEXTURE.get_width()) / 2.0), LOGO_Y)
	ui.add_child(logo)
	ui.add_child(PixelText.make(SUBTITLE, Vector2(UiTheme.VIEW.x / 2.0, SUBTITLE_Y), UiTheme.TEXT,
			PixelText.FONT_SMALL, PixelText.Align.CENTER))
	menu = MenuList.new()
	menu.position = MENU_POS
	ui.add_child(menu)
	menu.set_items(menu_items())
	menu.chosen.connect(_on_chosen)
	ui.add_child(PixelText.make("ARROWS + ENTER", Vector2(UiTheme.VIEW.x / 2.0, HINT_Y), UiTheme.DIM_TEXT,
			PixelText.FONT_SMALL, PixelText.Align.CENTER))
	_add_studio_logo(ui)


# Bottom-right animated GoDGuilD logo (intro, idle, occasional glitch replay).
func _add_studio_logo(parent: Node) -> void:
	var gg: TextureRect = GG_LOGO.new()
	gg.sheet_dir = GG_LOGO_DIR
	gg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	gg.position = UiTheme.VIEW - GG_LOGO_SIZE - Vector2(GG_LOGO_MARGIN, GG_LOGO_MARGIN)
	gg.size = GG_LOGO_SIZE
	parent.add_child(gg)


# CONTINUE is only enabled when a save exists.
func menu_items() -> Array:
	return [
		{"label": "CONTINUE", "enabled": SaveGame.has_save()},
		{"label": "NEW GAME", "enabled": true},
		{"label": "QUIT", "enabled": true},
	]


func _build_backdrop() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BACKDROP_AREA))
	_backdrop = Node2D.new()
	add_child(_backdrop)
	var actors := Node2D.new()
	actors.y_sort_enabled = true
	actors.process_mode = Node.PROCESS_MODE_DISABLED   # bushes and pots are scenery here
	var built := AreaBuilder.build(data["rows"], actors, false, false)
	_backdrop.add_child(built["tiles"])
	_backdrop.add_child(actors)
	var width := float(String(data["rows"][0]).length()) * TILE
	_pan_max = -PAN_START.x * TILE
	_pan_min = -(width - UiTheme.VIEW.x - PAN_START.x * TILE)
	_backdrop.position = -PAN_START * TILE


# Ping-pong drift across the village.
func _process(delta: float) -> void:
	_backdrop.position.x -= PAN_SPEED * delta * _pan_dir
	if _backdrop.position.x <= _pan_min:
		_pan_dir = -1.0
	elif _backdrop.position.x >= _pan_max:
		_pan_dir = 1.0


func _on_chosen(index: int) -> void:
	match index:
		ITEM_CONTINUE:
			start_game(true)
		ITEM_NEW:
			start_game(false)
		ITEM_QUIT:
			get_tree().quit()


# Begin a game: load the save (continue) or reset everything (new game), then switch to the world scene.
func start_game(continue_save: bool) -> void:
	if continue_save:
		var data := SaveGame.read()
		if data.is_empty():
			return
		SaveGame.pending = data
		started = "continue"
	else:
		SaveGame.pending = {}
		GameState.reset()
		started = "new"
	get_tree().change_scene_to_file(WORLD_SCENE)
