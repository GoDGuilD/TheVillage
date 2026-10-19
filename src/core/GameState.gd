# File: GameState.gd
# Description: Autoload holding run-wide state - gems, magic, small keys (one pool per dungeon), dungeon items, bombs/arrows, heart pieces, items, family seals, story flags, visited areas - plus the drop table, and the snapshot/restore used by saves.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-19
# Version: 3.0.2
extends Node
## Keep it data + small helpers only. Joe's own hearts live on his HealthComponent (the World copies them in and
## out of saves). Items are listed here so the item menu can show their slots; they are found from Phase 5 on.

signal gems_changed(amount: int)
signal magic_changed(current: int, maximum: int)
signal keys_changed(amount: int)
signal equipped_changed(item: String)
signal ammo_changed(bombs: int, arrows: int)

const MAX_GEMS := 999
const MAX_MAGIC := 32                    # one pixel of the HUD meter per unit
const MAX_KEYS := 9
const SEAL_COUNT := 3                    # the three family seals of the Light World dungeons
const MAX_BOMBS := 10
const MAX_ARROWS := 30
const PIECES_PER_HEART := 4             # four heart pieces make a heart container
# Y-button items in item-menu order (ALttP's subscreen); names match their future icon files.
const ITEM_ORDER := ["boomerang", "bow", "bombs", "lantern", "grapple",
		"fire_rod", "ice_rod", "hammer", "moon_mirror", "bottle"]
# Drop table rolled when an enemy dies or a pot breaks: [kind, weight]. "" = nothing.
const DROP_TABLE := [["", 42], ["heart", 20], ["gem_green", 22], ["gem_blue", 6], ["gem_red", 2], ["magic_small", 6],
		["magic_big", 2]]
const GEM_VALUES := {"gem_green": 1, "gem_blue": 5, "gem_red": 20}
const MAGIC_JARS := {"magic_small": 4, "magic_big": 16}    # magic units a jar refills (ALttP: 1/8 and 1/2)

var gems := 0
var magic := MAX_MAGIC
# Small keys belong to the place they were found (ALttP): one pool for the overworld ("") and one per dungeon.
# `keys` reads and writes the pool of wherever Joe is (the World calls set_key_pool on every area change).
var key_pool := ""
var key_pools: Dictionary = {}
var keys: int:
	get:
		return int(key_pools.get(key_pool, 0))
	set(value):
		key_pools[key_pool] = value
var dungeon_items: Dictionary = {}       # dungeon id -> {"map": true, "compass": true, "big_key": true}
var visited: Dictionary = {}             # area id -> true (the map screen draws visited rooms)
var bombs := 0
var arrows := 0
var heart_pieces := 0                    # 0..3 pieces toward the next container
var items: Dictionary = {}               # item id -> level/count (absent = not found)
var equipped := ""                       # the item in the HUD box ("" = none)
var seals: Array = [false, false, false]
var flags: Dictionary = {}               # story flags, e.g. "met_tato": true
var drops_enabled := true                # tests switch random drops off
var force_drop := ""                     # tests force a specific drop ("" = roll normally)
var rng := RandomNumberGenerator.new()


func add_gems(amount: int) -> void:
	gems = clampi(gems + amount, 0, MAX_GEMS)
	gems_changed.emit(gems)


# Spend magic; false (and nothing spent) if there is not enough.
func use_magic(amount: int) -> bool:
	if magic < amount:
		return false
	magic -= amount
	magic_changed.emit(magic, MAX_MAGIC)
	return true


func add_magic(amount: int) -> void:
	magic = clampi(magic + amount, 0, MAX_MAGIC)
	magic_changed.emit(magic, MAX_MAGIC)


func set_key_pool(pool: String) -> void:
	key_pool = pool
	keys_changed.emit(keys)


func has_dungeon_item(dungeon: String, item: String) -> bool:
	return bool(dungeon_items.get(dungeon, {}).get(item, false))


func give_dungeon_item(dungeon: String, item: String) -> void:
	if not dungeon_items.has(dungeon):
		dungeon_items[dungeon] = {}
	dungeon_items[dungeon][item] = true


func add_keys(amount: int) -> void:
	keys = clampi(keys + amount, 0, MAX_KEYS)
	keys_changed.emit(keys)


# Add bombs or arrows (clamped to the bag size); returns how many actually fit.
func add_ammo(kind: String, amount: int) -> int:
	var before := bombs if kind == "bombs" else arrows
	if kind == "bombs":
		bombs = clampi(bombs + amount, 0, MAX_BOMBS)
	else:
		arrows = clampi(arrows + amount, 0, MAX_ARROWS)
	ammo_changed.emit(bombs, arrows)
	return (bombs if kind == "bombs" else arrows) - before


# Spend one bomb / arrow; false if there is none.
func use_ammo(kind: String) -> bool:
	if (bombs if kind == "bombs" else arrows) <= 0:
		return false
	add_ammo(kind, -1)
	return true


func ammo_full(kind: String) -> bool:
	return bombs >= MAX_BOMBS if kind == "bombs" else arrows >= MAX_ARROWS


# One more heart piece; returns true when it completes a container (the counter wraps to 0).
func add_heart_piece() -> bool:
	heart_pieces += 1
	if heart_pieces >= PIECES_PER_HEART:
		heart_pieces = 0
		return true
	return false


func has_item(item: String) -> bool:
	return items.has(item)


func give_item(item: String, level: int = 1) -> void:
	items[item] = level
	if equipped == "" and ITEM_ORDER.has(item):        # passive gear (the glove) is never "equipped"
		equip(item)


func equip(item: String) -> void:
	if item != "" and not has_item(item):
		return
	equipped = item
	equipped_changed.emit(equipped)


func set_flag(flag: String, value: bool = true) -> void:
	flags[flag] = value


func has_flag(flag: String) -> bool:
	return bool(flags.get(flag, false))


func seal_count() -> int:
	return seals.count(true)


# Pick a drop kind ("" for none) from DROP_TABLE.
func roll_drop() -> String:
	if force_drop != "":
		return force_drop
	if not drops_enabled:
		return ""
	var total := 0
	for row in DROP_TABLE:
		total += int(row[1])
	var pick := rng.randi_range(1, total)
	for row in DROP_TABLE:
		pick -= int(row[1])
		if pick <= 0:
			return String(row[0])
	return ""


# Everything a save needs from this autoload.
func snapshot() -> Dictionary:
	return {"gems": gems, "magic": magic, "key_pools": key_pools.duplicate(), "dungeon_items": dungeon_items.duplicate(true),
			"visited": visited.keys(), "bombs": bombs, "arrows": arrows,
			"heart_pieces": heart_pieces, "items": items.duplicate(), "equipped": equipped,
			"seals": seals.duplicate(), "flags": flags.duplicate()}


# Put a snapshot back (missing fields fall back to a fresh game's values).
func restore(data: Dictionary) -> void:
	gems = clampi(int(data.get("gems", 0)), 0, MAX_GEMS)
	magic = clampi(int(data.get("magic", MAX_MAGIC)), 0, MAX_MAGIC)
	key_pool = ""
	key_pools = Dictionary(data.get("key_pools", {"": int(data.get("keys", 0))})).duplicate()
	for pool in key_pools:
		key_pools[pool] = clampi(int(key_pools[pool]), 0, MAX_KEYS)
	dungeon_items = Dictionary(data.get("dungeon_items", {})).duplicate(true)
	visited = {}
	for aid in data.get("visited", []):
		visited[String(aid)] = true
	bombs = clampi(int(data.get("bombs", 0)), 0, MAX_BOMBS)
	arrows = clampi(int(data.get("arrows", 0)), 0, MAX_ARROWS)
	heart_pieces = clampi(int(data.get("heart_pieces", 0)), 0, PIECES_PER_HEART - 1)
	items = Dictionary(data.get("items", {})).duplicate()
	equipped = String(data.get("equipped", ""))
	var s: Array = data.get("seals", [])
	seals = []
	for i in SEAL_COUNT:
		seals.append(i < s.size() and bool(s[i]))
	flags = Dictionary(data.get("flags", {})).duplicate()
	_emit_all()


# Back to a fresh run (title screen / tests).
func reset() -> void:
	restore({})
	drops_enabled = true
	force_drop = ""


func _emit_all() -> void:
	gems_changed.emit(gems)
	magic_changed.emit(magic, MAX_MAGIC)
	keys_changed.emit(keys)
	equipped_changed.emit(equipped)
	ammo_changed.emit(bombs, arrows)
