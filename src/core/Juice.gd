# File: Juice.gd
# Description: Autoload for game-feel effects - camera shake, per-actor hit-stop and one-shot effect sprites (ported from Chapel of Dreams, trimmed for top-down).
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.1.0
extends Node

const FX_DIR := "res://assets/sprites/vfx/"
const FX_MANIFESTS := ["vfx_manifest.json", "vfx_items.json"]   # gen_props.py / gen_items.py
const FX_Z := 60                          # effects draw over actors

# Debug/test counters.
var fx_count := 0
var last_fx := ""
var last_hit_stop := 0.0
var shake_left := 0.0

var _fx_index: Dictionary = {}            # effect name -> manifest entry
var _fx_frames: Dictionary = {}           # effect name -> SpriteFrames
var _shake_strength := 0.0
var _shake_total := 0.0


# Shake the active camera by up to `strength` whole pixels, decaying over `seconds`.
func shake(strength: float, seconds: float) -> void:
	_shake_strength = maxf(_shake_strength, strength)
	shake_left = maxf(shake_left, seconds)
	_shake_total = maxf(_shake_total, seconds)


func _process(delta: float) -> void:
	if shake_left <= 0.0:
		return
	shake_left -= delta
	var cam := get_viewport().get_camera_2d()
	var k := clampf(shake_left / maxf(_shake_total, 0.001), 0.0, 1.0)
	var amp := roundi(_shake_strength * k)
	if cam != null:
		cam.offset = Vector2(randi_range(-amp, amp), randi_range(-amp, amp))
	if shake_left <= 0.0:
		_shake_strength = 0.0
		_shake_total = 0.0
		if cam != null:
			cam.offset = Vector2.ZERO


# Freeze each actor that implements freeze(seconds): a short local hit-stop that stays deterministic in tests.
func hit_stop(actors: Array, seconds: float) -> void:
	last_hit_stop = seconds
	for a in actors:
		if is_instance_valid(a) and a.has_method("freeze"):
			a.freeze(seconds)


# Play a one-shot effect from assets/sprites/vfx (e.g. "poof", "hit_spark", "glint", "shards") centred on `world_pos`.
# `parent` defaults to the running scene (or the root in headless tests).
func play_fx(fx_name: String, world_pos: Vector2, parent: Node = null) -> void:
	_ensure_index()
	if not _fx_index.has(fx_name):
		push_warning("Juice: unknown effect '%s'" % fx_name)
		return
	if not _fx_frames.has(fx_name):
		var info: Dictionary = _fx_index[fx_name]
		var fs: Array = info["frame_size"]
		var frames := SpriteStrips.new_frames()
		SpriteStrips.add_strip(frames, "fx", FX_DIR + fx_name + ".png", Vector2i(int(fs[0]), int(fs[1])), float(info["fps"]), false)
		_fx_frames[fx_name] = frames
	var s := AnimatedSprite2D.new()
	s.sprite_frames = _fx_frames[fx_name]
	s.z_index = FX_Z
	s.position = world_pos
	s.animation_finished.connect(s.queue_free)
	var host := parent if parent != null else _world()
	host.add_child(s)
	s.play("fx")
	fx_count += 1
	last_fx = fx_name


func _ensure_index() -> void:
	if not _fx_index.is_empty():
		return
	for file in FX_MANIFESTS:
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FX_DIR + file))
		for key in manifest:
			_fx_index[String(key).trim_suffix(".png")] = manifest[key]


# Where world-space effects go: the running scene, or the root when none is set (headless tests).
func _world() -> Node:
	var scene := get_tree().current_scene
	return scene if scene != null else get_tree().root
