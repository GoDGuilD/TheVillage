# File: GameState.gd
# Description: Autoload holding run-wide state: gems (money) and the enemy/pot drop table with a seedable RNG.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
extends Node
## Grows with the game (inventory, flags, saves arrive in Phases 4-5). Keep it data + small helpers only.

signal gems_changed(amount: int)

const MAX_GEMS := 999
# Drop table rolled when an enemy dies or a pot breaks: [kind, weight]. "" = nothing.
const DROP_TABLE := [["", 50], ["heart", 20], ["gem_green", 22], ["gem_blue", 6], ["gem_red", 2]]
const GEM_VALUES := {"gem_green": 1, "gem_blue": 5, "gem_red": 20}

var gems := 0
var drops_enabled := true                # tests switch random drops off
var force_drop := ""                     # tests force a specific drop ("" = roll normally)
var rng := RandomNumberGenerator.new()


func add_gems(amount: int) -> void:
	gems = clampi(gems + amount, 0, MAX_GEMS)
	gems_changed.emit(gems)


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


# Back to a fresh run (title screen / tests).
func reset() -> void:
	gems = 0
	drops_enabled = true
	force_drop = ""
	gems_changed.emit(gems)
