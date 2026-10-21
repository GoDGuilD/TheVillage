# File: Audio.gd
# Description: Autoload audio system and settings keeper - pooled one-shot SFX (pitch jitter, per-effect loudness trims), looping area music with crossfades on its own bus, and the player settings (music and sound volume, language, fullscreen, vibration) saved to a small config file.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-21
# Version: 2.0.0
extends Node
## Ported from Chapel of Dreams and grown for Phase 14. Music tracks are generated WAVs (tools/gen_music.py) that
## loop forever; `play_music(track)` crossfades from the current one (two players). Volumes are levels 0..LEVELS
## applied to the "Music" and "SFX" buses (0 mutes). The settings file is read once at start-up; tests point
## `settings_path` at a throw-away file before changing anything.

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const SFX_BUS := "SFX"
const MUSIC_BUS := "Music"
const POOL_SIZE := 10                    # simultaneous sound effects
const SFX_VOLUME_DB := -4.0
const MUSIC_VOLUME_DB := -8.0            # music sits under the effects
const SILENT_DB := -40.0                 # where a crossfade starts / ends
const MUSIC_FADE := 0.8                  # s of a crossfade between two tracks
const DEFAULT_JITTER := 0.04             # +/- random pitch so repeated effects do not sound mechanical
const MIN_FRAMES_BETWEEN_SAME := 2       # the same effect is not restarted within this many physics frames
const HISTORY_LIMIT := 60
const BYTES_PER_SAMPLE := 2              # 16-bit mono WAV
const TRIM_FILE := "res://assets/audio/sfx_trim.json"     # per-effect loudness trims in dB (tools/balance_sfx.py)
const LEVELS := 10                       # volume steps in the options menu
const DEFAULT_LEVEL := 8
const SETTINGS_SECTION := "settings"
const DEFAULT_SETTINGS_PATH := "user://village_settings.cfg"

# Debug/test counters: what was last asked to play.
var play_count := 0
var last_sfx := ""
var history: Array[String] = []
var music_name := ""                     # the track playing (or fading in), "" = none
var music_changes := 0                   # tracks started (tests)
var sfx_trim: Dictionary = {}            # effect name -> dB
# Settings (read from / written to settings_path).
var settings_path := DEFAULT_SETTINGS_PATH
var music_level := DEFAULT_LEVEL
var sound_level := DEFAULT_LEVEL
var fullscreen := false
var vibration := true

var _streams: Dictionary = {}            # path -> AudioStream (or null when missing)
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _last_frame: Dictionary = {}         # sfx name -> physics frame it last played
var _music: Array[AudioStreamPlayer] = []    # two players: the current track and the one fading out
var _music_now := 0
var _fades: Array[Tween] = [null, null]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS              # music and menu sounds go on while the tree is paused
	_ensure_bus(SFX_BUS)
	_ensure_bus(MUSIC_BUS)
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		p.volume_db = SFX_VOLUME_DB
		add_child(p)
		_pool.append(p)
	for i in 2:
		var m := AudioStreamPlayer.new()
		m.bus = MUSIC_BUS
		m.volume_db = SILENT_DB
		add_child(m)
		_music.append(m)
	_load_trims()
	# A `-s` script (tests, captures, tools) runs the main loop with its own script: it never reads the player's
	# settings, so a Spanish or muted player setup cannot leak into a test run.
	if get_tree().get_script() == null:
		load_settings()
	else:
		reset_settings()


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


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
	p.volume_db = SFX_VOLUME_DB + volume_db + float(sfx_trim.get(sfx_name, 0.0))
	p.play()


# True if `sfx_name` was among the last `n` effects asked for (tests).
func played_recently(sfx_name: String, n: int = 10) -> bool:
	var start := maxi(0, history.size() - n)
	return history.slice(start).has(sfx_name)


# --- music ---------------------------------------------------------------------------------------

# Crossfade to looping track `track` (file name without extension); asking for the track already playing does
# nothing, "" fades the music out.
func play_music(track: String) -> void:
	if track == music_name:
		return
	if track == "":
		stop_music()
		return
	var stream := _load(MUSIC_DIR + track + ".wav")
	if stream == null:
		return
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = wav.data.size() / BYTES_PER_SAMPLE
	music_name = track
	music_changes += 1
	_fade(_music_now, SILENT_DB, true)
	_music_now = 1 - _music_now
	var p := _music[_music_now]
	p.stream = stream
	p.volume_db = SILENT_DB
	p.play()
	_fade(_music_now, MUSIC_VOLUME_DB, false)


func stop_music() -> void:
	music_name = ""
	_fade(_music_now, SILENT_DB, true)


func is_music_playing() -> bool:
	return music_name != "" and _music[_music_now].playing


func _fade(index: int, to_db: float, stop_after: bool) -> void:
	if _fades[index] != null and _fades[index].is_valid():
		_fades[index].kill()
	var p := _music[index]
	if not p.playing:
		return
	var tw := create_tween()
	tw.tween_property(p, "volume_db", to_db, MUSIC_FADE)
	if stop_after:
		tw.tween_callback(p.stop)
	_fades[index] = tw


# --- settings ------------------------------------------------------------------------------------

func set_music_level(level: int) -> void:
	music_level = clampi(level, 0, LEVELS)
	_apply_level(MUSIC_BUS, music_level)


func set_sound_level(level: int) -> void:
	sound_level = clampi(level, 0, LEVELS)
	_apply_level(SFX_BUS, sound_level)


# Level 0 mutes the bus; the others are a linear fraction of full volume.
func _apply_level(bus_name: String, level: int) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_mute(idx, level == 0)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(float(level) / LEVELS, 0.001)))


func bus_db(bus_name: String) -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name))


func bus_muted(bus_name: String) -> bool:
	return AudioServer.is_bus_mute(AudioServer.get_bus_index(bus_name))


# Windowed or fullscreen (nothing to do without a window, as in headless runs).
func set_fullscreen(on: bool) -> void:
	fullscreen = on
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)


func set_language(code: String) -> void:
	Loc.set_language(code)


func save_settings() -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value(SETTINGS_SECTION, "music", music_level)
	cfg.set_value(SETTINGS_SECTION, "sound", sound_level)
	cfg.set_value(SETTINGS_SECTION, "language", Loc.language)
	cfg.set_value(SETTINGS_SECTION, "fullscreen", fullscreen)
	cfg.set_value(SETTINGS_SECTION, "vibration", vibration)
	return cfg.save(settings_path) == OK


# Read the settings file (missing file or values: the defaults) and apply everything.
func load_settings() -> void:
	var cfg := ConfigFile.new()
	var ok := cfg.load(settings_path) == OK
	set_music_level(int(cfg.get_value(SETTINGS_SECTION, "music", DEFAULT_LEVEL)) if ok else DEFAULT_LEVEL)
	set_sound_level(int(cfg.get_value(SETTINGS_SECTION, "sound", DEFAULT_LEVEL)) if ok else DEFAULT_LEVEL)
	set_language(String(cfg.get_value(SETTINGS_SECTION, "language", Loc.DEFAULT)) if ok else Loc.DEFAULT)
	set_fullscreen(bool(cfg.get_value(SETTINGS_SECTION, "fullscreen", false)) if ok else false)
	vibration = bool(cfg.get_value(SETTINGS_SECTION, "vibration", true)) if ok else true


# Back to the defaults without touching the file (tests).
func reset_settings() -> void:
	set_music_level(DEFAULT_LEVEL)
	set_sound_level(DEFAULT_LEVEL)
	set_language(Loc.DEFAULT)
	set_fullscreen(false)
	vibration = true


# Read the generated loudness trims (an absent file just means no trims).
func _load_trims() -> void:
	if not FileAccess.file_exists(TRIM_FILE):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TRIM_FILE))
	if parsed is Dictionary:
		for key in parsed:
			if not String(key).begins_with("_"):
				sfx_trim[key] = float(parsed[key])
