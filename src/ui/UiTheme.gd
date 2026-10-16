# File: UiTheme.gd
# Description: Colour and layout tokens shared by every UI screen (HUD, dialogue box, menus, title, Game Over); mirrors the UI block of tools/palette.py.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.1
class_name UiTheme
extends RefCounted

const VIEW := Vector2(384, 216)

# Text colours (same hex values as UI_TEXT / UI_GOLD / UI_RIM_DARK / UI_TEXT_DIM in tools/palette.py).
const TEXT := Color("#f8f8f8")
const GOLD := Color("#f8d040")
const DISABLED := Color("#585c88")
const DIM_TEXT := Color("#8890b8")
const LIFE_RED := Color("#f05050")

# Full-screen overlays.
const DIM := Color(0.02, 0.02, 0.08, 0.6)            # behind pause / item menus
const TITLE_SHADE := Color(0.02, 0.02, 0.1, 0.55)    # over the title backdrop
const GAME_OVER_RED := Color(0.35, 0.0, 0.04, 1.0)   # the screen bleeds to this before black
const BLACK := Color(0.0, 0.0, 0.0, 1.0)

# Generated art (tools/gen_ui.py).
const BOX_TEXTURE := preload("res://assets/ui/menu/box.png")
const BOX_BORDER := 8
const CAPTION_TEXTURE := preload("res://assets/ui/menu/caption.png")
const CAPTION_BORDER := 5

# CanvasLayer order: world < HUD < captions < dialogue < menus < Game Over < door fade.
const LAYER_HUD := 10
const LAYER_DIALOGUE := 14
const LAYER_MENU := 16
const LAYER_GAME_OVER := 18
const LAYER_FADE := 20


# A nine-slice box (dialogue / menu panel) of `size` at `pos`.
static func box(pos: Vector2, size: Vector2, texture: Texture2D = BOX_TEXTURE, border: int = BOX_BORDER) -> NinePatchRect:
	var b := NinePatchRect.new()
	b.texture = texture
	b.patch_margin_left = border
	b.patch_margin_right = border
	b.patch_margin_top = border
	b.patch_margin_bottom = border
	b.position = pos
	b.size = size
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


# A full-view colour overlay.
static func overlay(color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.size = VIEW
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
