# File: GgLogo.gd
# Description: Godot 4 player for the animated GoDGuilD logo. A TextureRect that plays the
#              spritesheets from src/export_godot.py as intro -> idle loop -> every 25-55 s a
#              glitch-out and the intro again -> idle. Drop-in replacement for a static logo.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-20
# Last edit date: 2026-10-20
# Version: 1.0.0
#
# Usage (code):
#   var logo: TextureRect = preload("res://src/ui/GgLogo.gd").new()
#   logo.sheet_dir = "res://assets/ui/gg_logo/"
#   logo.custom_minimum_size = Vector2(150, 122)
#   parent.add_child(logo)
# The node sizes itself like any TextureRect (keep-aspect, centred). Pauses with the tree.
extends TextureRect

# --- Sheet layout: must match src/export_godot.py in the logo package ----------------------
const FPS := 15.0
const COLS := 8
const FRAME := Vector2(224, 182)
const FRAMES := {"intro": 48, "idle": 60, "glitch": 15}

## Folder holding gg_logo_intro.png, gg_logo_idle.png and gg_logo_glitch.png.
@export var sheet_dir := "res://assets/ui/gg_logo/"
## Play the build-up first. Off = start straight on the idle loop.
@export var play_intro := true
## Seconds between replays (random in this range). x <= 0 disables replays.
@export var replay_every := Vector2(25.0, 55.0)

var _sheets := {}            # name -> Texture2D
var _atlas := AtlasTexture.new()
var _clip := "idle"          # sheet currently playing
var _t := 0.0                # seconds into the current clip
var _next_replay := 0.0      # seconds of idle left before the next replay


func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for clip: String in FRAMES:
		_sheets[clip] = load(sheet_dir + "gg_logo_" + clip + ".png") as Texture2D
	texture = _atlas
	_play("intro" if play_intro else "idle")


# Start a clip from its first frame.
func _play(clip: String) -> void:
	_clip = clip
	_t = 0.0
	_atlas.atlas = _sheets[clip]
	if clip == "idle":
		_schedule_replay()
	_show_frame(0)


func _schedule_replay() -> void:
	_next_replay = randf_range(replay_every.x, replay_every.y) if replay_every.x > 0.0 else INF


# Point the shared AtlasTexture at one cell of the current sheet.
@warning_ignore("integer_division")
func _show_frame(i: int) -> void:
	_atlas.region = Rect2(Vector2(i % COLS, i / COLS) * FRAME, FRAME)


func _process(delta: float) -> void:
	_t += delta
	var count: int = FRAMES[_clip]
	var i := int(_t * FPS)
	match _clip:
		"intro":
			# One-shot: hand over to the idle loop when the build-up has finished.
			if i >= count:
				_play("idle")
				return
		"glitch":
			# Glitch-out ends on an empty frame; rebuild with the intro.
			if i >= count:
				_play("intro")
				return
		_:
			i %= count
			_next_replay -= delta
			# Only switch at the loop seam, so the idle never jumps mid-cycle.
			if _next_replay <= 0.0 and i == 0 and is_visible_in_tree():
				_play("glitch")
				return
	_show_frame(i)
