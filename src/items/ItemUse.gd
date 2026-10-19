# File: ItemUse.gd
# Description: What pressing the item button does with the equipped Y-item - throw the boomerang, shoot an arrow, set a bomb, hold out the lantern's flame (lighting a torch in front) or cast a fireball - including ammo and magic costs.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-20
# Version: 1.1.1
class_name ItemUse
extends RefCounted
## Called by the Player (state "use"); spawned objects go into Joe's parent (the y-sorted actors of the area).
## Returns true when the item was used (false = nothing happened, an error buzz was played).

const BOOMERANG := preload("res://src/items/Boomerang.gd")
const ARROW := preload("res://src/items/Arrow.gd")
const BOMB := preload("res://src/items/Bomb.gd")
const FIREBALL := preload("res://src/items/Fireball.gd")
const FIREBALL_AHEAD := 8.0
const MAX_BOMBS_OUT := 2                 # bombs ticking at the same time
const BOMB_AHEAD := 12.0                 # px in front of Joe's feet where a bomb is set down
const ARROW_AHEAD := 6.0
const FLAME_AHEAD := 16.0                # lantern flame / torch probe: one tile ahead, at tile-centre height
const FLAME_UP := Vector2(0, -6)
const TORCH_RADIUS := 11.0


static func use(player: Node2D, item: String, aim: Vector2) -> bool:
	var tree := player.get_tree()
	var state := tree.root.get_node("GameState")
	var parent := player.get_parent()
	var facing := Vector2(player.facing)
	match item:
		"boomerang":
			if not tree.get_nodes_in_group("boomerang").is_empty():
				return false
			var b: CharacterBody2D = BOOMERANG.new()
			b.direction = (aim if aim != Vector2.ZERO else facing).normalized()
			b.owner_node = player
			b.position = player.position
			parent.add_child(b)
			return true
		"bow":
			if not state.use_ammo("arrows"):
				return _fail()
			var a: CharacterBody2D = ARROW.new()
			a.direction = facing
			a.position = player.position + facing * ARROW_AHEAD
			parent.add_child(a)
			Audio.sfx("arrow_shot")
			return true
		"bombs":
			if tree.get_nodes_in_group("bomb").size() >= MAX_BOMBS_OUT or not state.use_ammo("bombs"):
				return _fail()
			var bomb: Node2D = BOMB.new()
			bomb.position = player.position + facing * BOMB_AHEAD
			parent.add_child(bomb)
			return true
		"lantern":
			if not state.use_magic(ItemDB.LANTERN_MAGIC):
				return _fail()
			var at := player.global_position + FLAME_UP + facing * FLAME_AHEAD
			Audio.sfx("lantern")
			Juice.play_fx("flame", at, parent)
			var torch := torch_near(tree, at)
			if torch != null:
				torch.call("light")
			return true
		"moon_mirror":
			player.emit_signal("mirror_requested")         # the World knows both worlds; it does the warp
			return true
		"fire_rod":
			if not state.use_magic(ItemDB.FIRE_ROD_MAGIC):
				return _fail()
			var f: CharacterBody2D = FIREBALL.new()
			f.direction = facing
			f.position = player.position + facing * FIREBALL_AHEAD
			parent.add_child(f)
			Audio.sfx("fireball")
			return true
	return false


# The unlit torch whose flame bowl is near `at`, or null.
static func torch_near(tree: SceneTree, at: Vector2) -> Node2D:
	for t in tree.get_nodes_in_group("torch"):
		var node := t as Node2D
		if node != null and not node.get("lit") and node.call("flame_point").distance_to(at) <= TORCH_RADIUS:
			return node
	return null


static func _fail() -> bool:
	Audio.sfx("error")
	return false
