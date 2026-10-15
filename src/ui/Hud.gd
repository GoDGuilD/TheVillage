# File: Hud.gd
# Description: Minimal in-game HUD: hearts (full/half/empty) top-left and the gem counter top-right; the full ALttP HUD comes in Phase 4.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
class_name Hud
extends CanvasLayer

const HEART_TEX := preload("res://assets/sprites/props/hud_heart.png")
const DIGIT_TEX := preload("res://assets/sprites/props/digits.png")
const GEM_TEX := preload("res://assets/sprites/props/gem_green.png")
const HEART_SIZE := Vector2i(9, 8)
const DIGIT_SIZE := Vector2i(5, 7)
const GEM_SIZE := Vector2i(10, 14)
const MARGIN := Vector2(6, 5)
const HEART_STEP := 9.0                  # px between hearts
const DIGIT_STEP := 4.0                  # digits overlap their outlines by one pixel
const GEM_DIGITS := 3
const VIEW_W := 384.0
const HEART_FULL := 0                    # frames in hud_heart.png
const HEART_HALF := 1
const HEART_EMPTY := 2

var hearts_shown := ""                   # e.g. "FFH" - tests read it
var gems_shown := 0

var _hearts: Array[Sprite2D] = []
var _digits: Array[Sprite2D] = []


func _ready() -> void:
	layer = 10
	var gem := Sprite2D.new()
	gem.texture = _atlas(GEM_TEX, 0, GEM_SIZE)
	gem.centered = false
	gem.position = Vector2(VIEW_W - MARGIN.x - GEM_DIGITS * DIGIT_STEP - GEM_SIZE.x - 2, MARGIN.y - 3)
	add_child(gem)
	for i in GEM_DIGITS:
		var d := Sprite2D.new()
		d.centered = false
		d.position = Vector2(VIEW_W - MARGIN.x - (GEM_DIGITS - i) * DIGIT_STEP - 1, MARGIN.y + 1)
		add_child(d)
		_digits.append(d)
	GameState.gems_changed.connect(set_gems)
	set_gems(GameState.gems)


func _atlas(tex: Texture2D, frame: int, size: Vector2i) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = tex
	a.region = Rect2(frame * size.x, 0, size.x, size.y)
	return a


# Draw ceil(maximum/2) heart containers filled with `current` half-hearts.
func set_health(current: int, maximum: int) -> void:
	var count := (maximum + 1) / 2
	while _hearts.size() < count:
		var s := Sprite2D.new()
		s.centered = false
		s.position = MARGIN + Vector2(_hearts.size() * HEART_STEP, 0)
		add_child(s)
		_hearts.append(s)
	hearts_shown = ""
	for i in _hearts.size():
		var fill := clampi(current - i * 2, 0, 2)
		var frame := HEART_FULL if fill == 2 else (HEART_HALF if fill == 1 else HEART_EMPTY)
		_hearts[i].texture = _atlas(HEART_TEX, frame, HEART_SIZE)
		_hearts[i].visible = i < count
		hearts_shown += "F" if fill == 2 else ("H" if fill == 1 else "E")


func set_gems(amount: int) -> void:
	gems_shown = amount
	var text := str(amount).pad_zeros(GEM_DIGITS)
	for i in GEM_DIGITS:
		_digits[i].texture = _atlas(DIGIT_TEX, int(text[i]), DIGIT_SIZE)
