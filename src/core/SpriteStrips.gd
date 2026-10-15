# File: SpriteStrips.gd
# Description: Static helper that turns generated horizontal PNG strips (and the Joe animation manifest) into SpriteFrames.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-12
# Last edit date: 2026-10-12
# Version: 1.2.0
class_name SpriteStrips
extends RefCounted


# Create an empty SpriteFrames without the auto-added "default" animation.
static func new_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	return frames


# Add one animation to `frames` by slicing a horizontal strip of equally sized frames.
static func add_strip(frames: SpriteFrames, anim: String, path: String, frame_size: Vector2i, fps: float, loop: bool) -> void:
	var tex: Texture2D = load(path)
	var count: int = tex.get_width() / frame_size.x
	frames.add_animation(anim)
	frames.set_animation_speed(anim, fps)
	frames.set_animation_loop(anim, loop)
	for i in count:
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * frame_size.x, 0, frame_size.x, frame_size.y)
		frames.add_frame(anim, atlas)


# Load an enemy-style pack: `<dir><pack>.json` (frame_size + anims) and `<dir><pack>_<anim>.png` strips.
# Returns {"frames": SpriteFrames, "info": the parsed manifest}.
static func load_pack(dir: String, pack: String) -> Dictionary:
	var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir + pack + ".json"))
	var fs: Array = m["frame_size"]
	var size := Vector2i(fs[0], fs[1])
	var frames := new_frames()
	for anim in m["anims"]:
		var info: Dictionary = m["anims"][anim]
		add_strip(frames, anim, dir + "%s_%s.png" % [pack, anim], size, info["fps"], info["loop"])
	return {"frames": frames, "info": m}


# Joe's animation manifest ({anim: {frames, fps, loop, hit_window?, release_frame?}}) from `dir`.
static func load_joe_manifest(dir: String) -> Dictionary:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir + "joe_animations.json"))
	return manifest["anims"]


# Build Joe's full SpriteFrames from `joe_animations.json` + `joe_<anim>.png` strips in `dir`.
static func load_joe(dir: String) -> SpriteFrames:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir + "joe_animations.json"))
	var fs: Array = manifest["frame_size"]
	var size := Vector2i(fs[0], fs[1])
	var frames := new_frames()
	for anim in manifest["anims"]:
		var info: Dictionary = manifest["anims"][anim]
		add_strip(frames, anim, dir + "joe_%s.png" % anim, size, info["fps"], info["loop"])
	return frames
