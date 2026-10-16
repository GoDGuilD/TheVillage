# File: DialogueData.gd
# Description: Reads assets/data/dialogue.json and answers "what does this villager or sign say now?", honouring first-meeting lines and their story flags.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.1.0
class_name DialogueData
extends RefCounted
## Entry format: {name?, pages: [...], once?: [...], flag?, gift?: {item, amount?, flag, pages}}. The first talk
## says `once` and sets `flag` in GameState.flags. The next talk (once `flag` is set) hands over a `gift` if it has
## one that is not given yet: it says the gift's pages, and the World runs the item-get for `item`. After that,
## `pages`. Keys starting with "_" are file metadata.

const PATH := "res://assets/data/dialogue.json"

static var _entries: Dictionary = {}


static func _load() -> Dictionary:
	if _entries.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary:
			for key in parsed:
				if not String(key).begins_with("_"):
					_entries[key] = parsed[key]
	return _entries


static func has(key: String) -> bool:
	return _load().has(key)


# Speaker name for the box's name plate ("" for signs).
static func speaker(key: String) -> String:
	return String(_load().get(key, {}).get("name", ""))


# The pages to show for `key` right now. `state` is the GameState autoload (passed in so tests and tools can
# use this class without autoloads); the first-meeting flag is set as a side effect.
static func pages_for(key: String, state: Node) -> Array[String]:
	return conversation(key, state)["pages"]


# {pages: Array[String], gift: String (an ItemDB kind or ""), amount: int} for `key` right now; sets the
# first-meeting flag or the gift's flag as a side effect.
static func conversation(key: String, state: Node) -> Dictionary:
	var out: Array[String] = []
	var result := {"pages": out, "gift": "", "amount": 0}
	var e: Dictionary = _load().get(key, {})
	if e.is_empty():
		return result
	var lines: Array = e.get("pages", [])
	var gift: Dictionary = e.get("gift", {})
	if e.has("once") and e.has("flag") and not state.has_flag(String(e["flag"])):
		lines = e["once"]
		state.set_flag(String(e["flag"]))
	elif not gift.is_empty() and not state.has_flag(String(gift["flag"])):
		lines = gift.get("pages", [])
		state.set_flag(String(gift["flag"]))
		result["gift"] = String(gift["item"])
		result["amount"] = int(gift.get("amount", 1))
	for l in lines:
		out.append(String(l))
	return result
