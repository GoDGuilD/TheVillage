# File: SaveGame.gd
# Description: Save/load of the game to one JSON file - where Joe stands (area + entry point), his hearts and the GameState snapshot; static helpers only.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
class_name SaveGame
extends RefCounted
## Ported from Chapel of Dreams. Joe is saved at the point where he entered his current area (a door, a mat or a
## screen edge), the ALttP way: a loaded game never starts him in the middle of a fight.

const VERSION := 1

# Where the save lives. Tests point this at a throw-away file.
static var path := "user://village_save.json"
# A loaded save waiting for the World scene to apply it (set by the title screen's CONTINUE).
static var pending: Dictionary = {}


static func has_save() -> bool:
	return FileAccess.file_exists(path)


static func delete() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


# Write `data` as JSON; returns true on success.
static func write(data: Dictionary) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("SaveGame: cannot write %s (error %d)" % [path, FileAccess.get_open_error()])
		return false
	f.store_string(JSON.stringify(data, "\t"))
	return true


# The saved dictionary, or {} if there is none, it is unreadable or it comes from another version.
static func read() -> Dictionary:
	if not has_save():
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary) or int(parsed.get("version", 0)) != VERSION:
		return {}
	return parsed


# Snapshot of the running game. `state` is the GameState autoload.
static func capture(area_id: String, feet: Vector2, facing: Vector2i, hp: int, max_hp: int, state: Node) -> Dictionary:
	return {
		"version": VERSION,
		"area": area_id,
		"pos": [feet.x, feet.y],
		"facing": [facing.x, facing.y],
		"hp": hp,
		"max_hp": max_hp,
		"state": state.snapshot(),
		"saved_at": Time.get_datetime_string_from_system(),
	}
