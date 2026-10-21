# File: Loc.gd
# Description: Localization - translates in-game English text through localization/<lang>.json (exact strings and printf-style patterns such as "KEYS %d"); unknown text passes through unchanged. PixelText calls it for what it draws, DialogueData reads the language to pick its dialogue table.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-21
# Last edit date: 2026-10-21
# Version: 1.0.0
class_name Loc
extends RefCounted
## Ported from Chapel of Dreams (same table format, so the trilogy shares one translation method). Static so tests
## and tools can use it without autoloads. Texts drawn while one language is in force are re-translated in place
## by `refresh(tree)` (PixelText nodes join the group LIVE_GROUP and remember their English source).

const DEFAULT := "en"
const LANGUAGES := ["en", "es"]
const LABELS := {"en": "ENGLISH", "es": "ESPAÑOL"}
const TABLE_PATH := "res://localization/%s.json"
const LIVE_GROUP := "loc_text"           # PixelText nodes that translate what they draw
# printf placeholder -> regex that captures what it stands for (padded numbers may be preceded by spaces).
const PLACEHOLDER := "%[-+0-9.]*[sdf]"
const NUMBER_CAPTURE := "\\s*(-?[\\d.]+)"
const TEXT_CAPTURE := "(.+?)"

static var language := DEFAULT

static var _exact: Dictionary = {}
static var _patterns: Array = []              # [{"regex": RegEx, "value": String}] longest key first


# Switch language (an unknown code falls back to English). Returns the language actually in force.
static func set_language(code: String) -> String:
	language = code if code in LANGUAGES else DEFAULT
	_exact.clear()
	_patterns.clear()
	if language != DEFAULT:
		_load_table(TABLE_PATH % language)
	return language


# The next language in the list (the options menu cycles through them).
static func next_language(code: String) -> String:
	return LANGUAGES[(LANGUAGES.find(code) + 1) % LANGUAGES.size()]


# Translate `text`: an exact table entry, else a pattern entry, else the text itself.
static func t(text: String) -> String:
	if language == DEFAULT or text == "":
		return text
	if _exact.has(text):
		return _exact[text]
	for p in _patterns:
		var m: RegExMatch = p["regex"].search(text)
		if m != null and m.get_string() == text:
			return _fill(p["value"], m)
	return text


# Re-translate every live PixelText in `tree` (after a language change, so open screens follow at once).
static func refresh(tree: SceneTree) -> void:
	for n in tree.get_nodes_in_group(LIVE_GROUP):
		n.call("retranslate")


static func _load_table(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_warning("Loc: no translation table at %s" % path)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		push_warning("Loc: %s is not a JSON object" % path)
		return
	var holder := RegEx.new()
	holder.compile(PLACEHOLDER)
	var keyed: Array = []
	for key in parsed:
		if String(key).begins_with("_"):
			continue                          # file metadata (the branding header)
		if holder.search(key) == null:
			_exact[key] = parsed[key]
		else:
			keyed.append(key)
	keyed.sort_custom(func(a, b): return a.length() > b.length())      # the most specific pattern wins
	for key in keyed:
		var rx := RegEx.new()
		if rx.compile(_pattern_of(key, holder)) == OK:
			_patterns.append({"regex": rx, "value": parsed[key]})


# "KEYS %d" -> "^KEYS \s*(-?[\d.]+)$" (literal parts escaped).
static func _pattern_of(key: String, holder: RegEx) -> String:
	var out := "^"
	var at := 0
	for m in holder.search_all(key):
		out += _escape(key.substr(at, m.get_start() - at))
		out += TEXT_CAPTURE if m.get_string().ends_with("s") else NUMBER_CAPTURE
		at = m.get_end()
	return out + _escape(key.substr(at)) + "$"


static func _escape(literal: String) -> String:
	var special := "\\.^$|()[]{}*+?"
	var out := ""
	for c in literal:
		out += ("\\" + c) if special.contains(c) else c
	return out


# Put the captured values into the translation's placeholders, in order; text (%s) is translated too, so
# "PRESS %s" with "CIRCLE" becomes "PULSA CÍRCULO".
static func _fill(value: String, m: RegExMatch) -> String:
	var holder := RegEx.new()
	holder.compile(PLACEHOLDER)
	var out := ""
	var at := 0
	var group := 1
	for ph in holder.search_all(value):
		var part := m.get_string(group)
		out += value.substr(at, ph.get_start() - at) + (t(part) if ph.get_string().ends_with("s") else part)
		at = ph.get_end()
		group += 1
	return out + value.substr(at)
