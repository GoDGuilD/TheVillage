# File: Audio.gd
# Description: Autoload audio system - pooled one-shot SFX with pitch jitter and an SFX bus (ported from Chapel of Dreams; music and settings arrive in later phases).
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
extends Node

const SFX_DIR := "res://assets/audio/sfx/"
const SFX_BUS := "SFX"
const POOL_SIZE := 10                    # simultaneous sound effects
const SFX_VOLUME_DB := -4.0
const DEFAULT_JITTER := 0.04             # +/- random pitch so repeated effects do not sound mechanical
const MIN_FRAMES_BETWEEN_SAME := 2       # the same effect is not restarted within this many physics frames
const HISTORY_LIMIT := 60

# Debug/test counters: what was last asked to play.
var play_count := 0
var last_sfx := ""
var history: Array[String] = []

var _streams: Dictionary = {}            # path -> AudioStream (or null when missing)
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _last_frame: Dictionary = {}         # sfx name -> physics frame it last played


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if AudioServer.get_bus_index(SFX_BUS) == -1:
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, SFX_BUS)
		AudioServer.set_bus_send(idx, "Master")
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		p.volume_db = SFX_VOLUME_DB
		add_child(p)
		_pool.append(p)


func _load(path: String) -> AudioStream:
	if not _streams.has(path):
		if not ResourceLoader.exists(path):
			push_warning("Audio: missing %s" % path)
			_streams[path] = null             # remembered so the warning appears once
			return null
		_streams[path] = load(path)
	return _streams[path]


# Play sound effect `sfx_name` (file name without extension).
func sfx(sfx_name: String, pitch: float = 1.0, volume_db: float = 0.0, jitter: float = DEFAULT_JITTER) -> void:
	var frame := Engine.get_physics_frames()
	if _last_frame.get(sfx_name, -1000) + MIN_FRAMES_BETWEEN_SAME > frame:
		return
	_last_frame[sfx_name] = frame
	play_count += 1
	last_sfx = sfx_name
	history.append(sfx_name)
	if history.size() > HISTORY_LIMIT:
		history.pop_front()
	var stream := _load(SFX_DIR + sfx_name + ".wav")
	if stream == null:
		return
	var p := _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = stream
	p.pitch_scale = pitch * (1.0 + randf_range(-jitter, jitter))
	p.volume_db = SFX_VOLUME_DB + volume_db
	p.play()


# True if `sfx_name` was among the last `n` effects asked for (tests).
func played_recently(sfx_name: String, n: int = 10) -> bool:
	var start := maxi(0, history.size() - n)
	return history.slice(start).has(sfx_name)
