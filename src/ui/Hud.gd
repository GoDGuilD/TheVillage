# File: Hud.gd
# Description: The ALttP-style HUD - magic meter and equipped-item box top-left, gem and key counters beside them, "- LIFE -" and the heart rows top-right - plus the area-name caption.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 2.0.0
class_name Hud
extends CanvasLayer
## Reads GameState through its signals; the World feeds Joe's hearts (set_health) and area names (show_caption).
## Item icons arrive with the items in Phase 5 (the box shows the equipped item's icon if one exists).

const HEART_TEX := preload("res://assets/sprites/props/hud_heart.png")
const DIGIT_TEX := preload("res://assets/sprites/props/digits.png")
const GEM_TEX := preload("res://assets/sprites/props/gem_green.png")
const MAGIC_FRAME_TEX := preload("res://assets/ui/hud/magic_frame.png")
const MAGIC_FILL_TEX := preload("res://assets/ui/hud/magic_fill.png")
const ITEM_BOX_TEX := preload("res://assets/ui/hud/item_box.png")
const KEY_TEX := preload("res://assets/ui/hud/key.png")
const ITEM_ICON_DIR := "res://assets/ui/items/"
const HEART_SIZE := Vector2i(9, 8)
const DIGIT_SIZE := Vector2i(5, 7)
const GEM_SIZE := Vector2i(10, 14)
const HEART_FULL := 0                    # frames in hud_heart.png
const HEART_HALF := 1
const HEART_EMPTY := 2

# Layout (384 x 216 view).
const MAGIC_POS := Vector2(8, 5)
const MAGIC_FILL_OFFSET := Vector2(3, 3)
const ITEM_BOX_POS := Vector2(22, 7)
const GEM_POS := Vector2(54, 6)
const GEM_DIGITS_POS := Vector2(66, 10)
const GEM_DIGITS := 3
const KEY_POS := Vector2(88, 8)
const KEY_DIGIT_POS := Vector2(97, 10)
const DIGIT_STEP := 4.0                  # digits overlap their outlines by one pixel
const LIFE_LABEL_POS := Vector2(334, 4)  # centre of "- LIFE -"
const HEARTS_POS := Vector2(290, 13)
const HEART_STEP := 9.0
const HEARTS_PER_ROW := 10
const HEART_ROW_STEP := 9.0

# Area caption: a plate centred under the HUD, faded in, held, faded out.
const CAPTION_Y := 40.0
const CAPTION_PAD := Vector2(8, 4)
const CAPTION_IN := 0.25
const CAPTION_HOLD := 1.6
const CAPTION_OUT := 0.4

var hearts_shown := ""                   # e.g. "FFH" - tests read it
var gems_shown := 0
var magic_shown := 0
var keys_shown := 0
var caption_shown := ""                  # the last caption text shown (tests)

var _hearts: Array[Sprite2D] = []
var _gem_digits: Array[Sprite2D] = []
var _key_icon: Sprite2D
var _key_digit: Sprite2D
var _magic_fill: Sprite2D
var _item_icon: Sprite2D
var _caption: Control
var _caption_text: PixelText
var _caption_tween: Tween


func _ready() -> void:
	layer = UiTheme.LAYER_HUD
	_sprite(MAGIC_FRAME_TEX, MAGIC_POS)
	_magic_fill = _sprite(MAGIC_FILL_TEX, MAGIC_POS + MAGIC_FILL_OFFSET)
	_magic_fill.region_enabled = true
	_sprite(ITEM_BOX_TEX, ITEM_BOX_POS)
	_item_icon = Sprite2D.new()
	_item_icon.position = ITEM_BOX_POS + Vector2(ITEM_BOX_TEX.get_size()) / 2.0
	add_child(_item_icon)
	_sprite(_atlas(GEM_TEX, 0, GEM_SIZE), GEM_POS)
	for i in GEM_DIGITS:
		_gem_digits.append(_sprite(null, GEM_DIGITS_POS + Vector2(i * DIGIT_STEP, 0)))
	_key_icon = _sprite(KEY_TEX, KEY_POS)
	_key_digit = _sprite(null, KEY_DIGIT_POS)
	add_child(PixelText.make("- LIFE -", LIFE_LABEL_POS, UiTheme.LIFE_RED, PixelText.FONT_LARGE, PixelText.Align.CENTER))
	_build_caption()
	GameState.gems_changed.connect(set_gems)
	GameState.magic_changed.connect(set_magic)
	GameState.keys_changed.connect(set_keys)
	GameState.equipped_changed.connect(set_item)
	set_gems(GameState.gems)
	set_magic(GameState.magic, GameState.MAX_MAGIC)
	set_keys(GameState.keys)
	set_item(GameState.equipped)


func _sprite(tex: Texture2D, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.position = pos
	add_child(s)
	return s


func _atlas(tex: Texture2D, frame: int, size: Vector2i) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = tex
	a.region = Rect2(frame * size.x, 0, size.x, size.y)
	return a


# Draw ceil(maximum/2) heart containers (10 per row) filled with `current` half-hearts.
func set_health(current: int, maximum: int) -> void:
	var count := (maximum + 1) / 2
	while _hearts.size() < count:
		var i := _hearts.size()
		_hearts.append(_sprite(null, HEARTS_POS + Vector2((i % HEARTS_PER_ROW) * HEART_STEP, (i / HEARTS_PER_ROW) * HEART_ROW_STEP)))
	hearts_shown = ""
	for i in _hearts.size():
		var fill := clampi(current - i * 2, 0, 2)
		var frame := HEART_FULL if fill == 2 else (HEART_HALF if fill == 1 else HEART_EMPTY)
		_hearts[i].texture = _atlas(HEART_TEX, frame, HEART_SIZE)
		_hearts[i].visible = i < count
		if i < count:
			hearts_shown += "F" if fill == 2 else ("H" if fill == 1 else "E")


func set_gems(amount: int) -> void:
	gems_shown = amount
	var text := str(amount).pad_zeros(GEM_DIGITS)
	for i in GEM_DIGITS:
		_gem_digits[i].texture = _atlas(DIGIT_TEX, int(text[i]), DIGIT_SIZE)


# The meter shows the bottom `current / maximum` of the fill column.
func set_magic(current: int, maximum: int) -> void:
	magic_shown = current
	var h := MAGIC_FILL_TEX.get_height()
	var shown := int(roundf(float(h) * float(current) / float(maxi(maximum, 1))))
	_magic_fill.region_rect = Rect2(0, h - shown, MAGIC_FILL_TEX.get_width(), shown)
	_magic_fill.position = MAGIC_POS + MAGIC_FILL_OFFSET + Vector2(0, h - shown)
	_magic_fill.visible = shown > 0


# Small keys only matter once Joe holds one (dungeons, Phase 6): the counter hides at zero.
func set_keys(amount: int) -> void:
	keys_shown = amount
	_key_icon.visible = amount > 0
	_key_digit.visible = amount > 0
	_key_digit.texture = _atlas(DIGIT_TEX, clampi(amount, 0, 9), DIGIT_SIZE)


func set_item(item: String) -> void:
	var path := ITEM_ICON_DIR + item + ".png"
	_item_icon.texture = load(path) if item != "" and ResourceLoader.exists(path) else null


# --- area caption ------------------------------------------------------------------------------

func _build_caption() -> void:
	_caption = Control.new()
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.modulate.a = 0.0
	add_child(_caption)


func show_caption(text: String) -> void:
	caption_shown = text
	for c in _caption.get_children():
		c.queue_free()
	var w := PixelText.measure(text) + CAPTION_PAD.x * 2.0
	var h := PixelText.line_height() + CAPTION_PAD.y * 2.0
	var x := roundf((UiTheme.VIEW.x - w) / 2.0)
	_caption.add_child(UiTheme.box(Vector2(x, CAPTION_Y), Vector2(w, h), UiTheme.CAPTION_TEXTURE, UiTheme.CAPTION_BORDER))
	_caption_text = PixelText.make(text, Vector2(UiTheme.VIEW.x / 2.0, CAPTION_Y + CAPTION_PAD.y), UiTheme.GOLD,
			PixelText.FONT_LARGE, PixelText.Align.CENTER)
	_caption.add_child(_caption_text)
	if _caption_tween != null:
		_caption_tween.kill()
	_caption.modulate.a = 0.0
	_caption_tween = create_tween()
	_caption_tween.tween_property(_caption, "modulate:a", 1.0, CAPTION_IN)
	_caption_tween.tween_interval(CAPTION_HOLD)
	_caption_tween.tween_property(_caption, "modulate:a", 0.0, CAPTION_OUT)


func caption_visible() -> bool:
	return _caption.modulate.a > 0.0
