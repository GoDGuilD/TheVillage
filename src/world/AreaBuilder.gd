# File: AreaBuilder.gd
# Description: Shared painter that turns ASCII area rows into a TileMapLayer (autotiled paths, water, ledges, cliffs, walls, multi-cell trees/houses/furniture) and actors.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-22
# Version: 2.3.0
class_name AreaBuilder
extends RefCounted
## Glyphs (outdoors):  . , *  grass / tufts / flowers   #  dirt path   ~  water   v  ledge (hop down south)
##                     ^  cliff   f  fence   S  sign   R  rock   T  2x2 tree   H / J  5x4 house (red / blue roof)
##                     x  filler cell of a multi-cell piece (painted by its anchor)
## Glyphs (indoors):   _  floor   W  wall (face or top, chosen by the cell below)   w  wall with a shelf
##                     M  exit mat   K  2x1 table   D  1x2 bed
## Actors on any ground: B bush, O pot, Z slime, G guard, Q rock-spitter, P Joe's spawn (test fields only).
## N marks a villager's cell (ground is painted; the World places the Npc from the area's "npcs" list,
## and makes each S readable from its "signs" list).
## Glyphs (dungeons):  =  stone floor   ;  cracked floor   %  dungeon wall (face or top)   o  pit (Joe falls in)
##                     +  pillar   s  exit stairs   E  5x3 shrine entrance (overworld; door at (2,2))
## Object cells (ground painted, the World builds the node from the area's "objects"): C chest, L torch,
## k cracked rock, l key block, h heart piece, [ door, @ floor switch, & push block, $ big chest (2x1), r heavy rock.
## k cracked rock ... b rubble (the dash breaks it). A bat. Bosses: Y Grand Slime, U Iron Ram, F Frost Wraith,
## V Caver's shade.
## The source of these rows is tools/gen_areas.py (areas) or TestField.layout (test arenas).

const TILE := 16
const ATLAS_TEX := preload("res://assets/tiles/overworld_light.png")
const DARK_ATLAS_TEX := preload("res://assets/tiles/overworld_dark.png")   # same cells, Dark World colours (gen_dark.py)
const ATLAS_JSON := "res://assets/tiles/overworld_light.json"
const LAYER_WORLD := 1
const ENEMY_SCRIPTS := {"Z": "res://src/enemies/Slime.gd", "G": "res://src/enemies/Guard.gd",
		"Q": "res://src/enemies/Spitter.gd", "Y": "res://src/enemies/GrandSlime.gd", "A": "res://src/enemies/Bat.gd",
		"U": "res://src/enemies/IronRam.gd", "F": "res://src/enemies/FrostWraith.gd", "V": "res://src/enemies/CaverShade.gd",
		"X": "res://src/enemies/Lurker.gd", "m": "res://src/enemies/GloomMoth.gd",
		"c": "res://src/enemies/Cinder.gd", "I": "res://src/enemies/MagmaWyrm.gd"}
const GRASS := {".": "grass_a", ",": "grass_b", "*": "flowers"}
const SIMPLE := {"R": "rock", "f": "fence", "S": "sign", "_": "floor", "M": "mat", "=": "dfloor", ";": "dfloor_b",
		"+": "pillar", "s": "dstairs"}
const WALLS := "Ww"
const DWALLS := "%"
const HOUSES := {"H": "red", "J": "blue"}
const HOUSE_SIZE := Vector2i(5, 4)
const HOUSE_DOOR := Vector2i(2, 3)
const SHRINE_SIZE := Vector2i(5, 3)
const SHRINE_DOOR := Vector2i(2, 2)
const LAYER_PIT := 256                   # pits are walls for enemies only (Joe walks in and falls)
# Custom data layers on the TileSet (read by Player and the World).
const DATA_FLAGS := ["ledge", "door", "exit", "pit", "low", "lava"]   # low: water, pits and lava (the grapple
                                                                       # flies over them); lava: the ice rod freezes it

static var _tilesets: Dictionary = {}    # false -> Light World TileSet, true -> Dark World TileSet
static var _cells: Dictionary = {}       # atlas cell name -> Vector2i
static var _crust_under: Dictionary = {}          # frozen lava: key -> the lava piece under the crust
static var _crust_gen: Dictionary = {}            # key -> how many times it was frozen (newest timer wins)


# The shared TileSet, built once from the atlas manifest: one physics layer, flag custom-data layers.
static func tileset(dark: bool = false) -> TileSet:
	if _tilesets.has(dark):
		return _tilesets[dark]
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ATLAS_JSON))
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, LAYER_WORLD)
	ts.set_physics_layer_collision_mask(0, 0)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(1, LAYER_PIT)
	ts.set_physics_layer_collision_mask(1, 0)
	for i in DATA_FLAGS.size():
		ts.add_custom_data_layer()
		ts.set_custom_data_layer_name(i, DATA_FLAGS[i])
		ts.set_custom_data_layer_type(i, TYPE_BOOL)
	var src := TileSetAtlasSource.new()
	src.texture = DARK_ATLAS_TEX if dark else ATLAS_TEX
	src.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(src, 0)
	var half := TILE / 2.0
	var square := PackedVector2Array([Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)])
	for cell_name in manifest["cells"]:
		var info: Dictionary = manifest["cells"][cell_name]
		var at := Vector2i(int(info["cell"][0]), int(info["cell"][1]))
		_cells[cell_name] = at
		src.create_tile(at)
		var td := src.get_tile_data(at, 0)
		if info["solid"]:
			td.add_collision_polygon(0)
			td.set_collision_polygon_points(0, 0, square)
		if info.get("pit", false):
			td.add_collision_polygon(1)
			td.set_collision_polygon_points(1, 0, square)
		for flag in DATA_FLAGS:
			td.set_custom_data(flag, bool(info.get(flag, false)))
	_tilesets[dark] = ts
	return ts


# Paint `rows` into a new TileMapLayer and create the actors in `actors`.
# Returns {tiles, bushes, pots, enemies, spawn (Vector2 or null), doors: [Vector2i], exits: [Vector2i]}.
static func build(rows: Array, actors: Node2D, indoor: bool = false, with_enemies: bool = true, origin: Vector2 = Vector2.ZERO, dungeon: bool = false, dark: bool = false) -> Dictionary:
	var tiles := TileMapLayer.new()
	tiles.name = "Tiles"
	tiles.tile_set = tileset(dark)
	tiles.position = origin
	tiles.add_to_group("terrain")
	var out := {"tiles": tiles, "bushes": [], "pots": [], "enemies": [], "spawn": null, "doors": [], "exits": []}
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var g := row[x]
			_paint_cell(tiles, rows, x, y, g, indoor, out, dungeon)
			var at := origin + Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)
			var feet := origin + Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE - 2)
			if g == "B":
				var b := Bush.new()
				b.position = at
				actors.add_child(b)
				out["bushes"].append(b)
			elif g == "O":
				var p := Pot.new()
				p.position = at
				actors.add_child(p)
				out["pots"].append(p)
			elif ENEMY_SCRIPTS.has(g) and with_enemies:
				var e: Node2D = load(ENEMY_SCRIPTS[g]).new()
				e.position = feet
				actors.add_child(e)
				out["enemies"].append(e)
			elif g == "P":
				out["spawn"] = feet
	return out


static func glyph(rows: Array, x: int, y: int) -> String:
	if y < 0 or y >= rows.size():
		return ""
	var row: String = rows[y]
	if x < 0 or x >= row.length():
		return ""
	return row[x]


static func _put(tiles: TileMapLayer, x: int, y: int, cell_name: String) -> void:
	tiles.set_cell(Vector2i(x, y), 0, _cells[cell_name])


static func _paint_cell(tiles: TileMapLayer, rows: Array, x: int, y: int, g: String, indoor: bool, out: Dictionary, dungeon: bool = false) -> void:
	if g == "x":
		return                                                  # painted by its anchor
	if GRASS.has(g):
		_put(tiles, x, y, GRASS[g])
	elif SIMPLE.has(g):
		_put(tiles, x, y, SIMPLE[g])
		if g == "M" or g == "s":
			out["exits"].append(Vector2i(x, y))
	elif g == "#":
		_put(tiles, x, y, _nine(rows, x, y, "#", "path"))
	elif g == "~":
		_put(tiles, x, y, _nine(rows, x, y, "~", "water"))
	elif g == "o":
		_put(tiles, x, y, _nine(rows, x, y, "o", "pit"))
	elif g == "!":
		_put(tiles, x, y, _nine(rows, x, y, "!", "lava"))
	elif g == "a":
		_put(tiles, x, y, _ash(x, y))
	elif g in DWALLS:
		var under := glyph(rows, x, y + 1)
		_put(tiles, x, y, "dwall_face" if under != "" and not under in DWALLS else "dwall_top")
	elif g == "$":                                             # big chest anchor: floor under both of its cells
		_put(tiles, x, y, "dfloor")
		_put(tiles, x + 1, y, "dfloor")
	elif g == "E":
		for ty in SHRINE_SIZE.y:
			for tx in SHRINE_SIZE.x:
				_put(tiles, x + tx, y + ty, "shrine_%d_%d" % [tx, ty])
		out["doors"].append(Vector2i(x, y) + SHRINE_DOOR)
	elif g == "v":
		var l := glyph(rows, x - 1, y) != "v"
		var r := glyph(rows, x + 1, y) != "v"
		_put(tiles, x, y, "ledge_s" if l and r else ("ledge_l" if l else ("ledge_r" if r else "ledge_m")))
	elif g == "^":
		_put(tiles, x, y, "cliff" if glyph(rows, x, y - 1) == "^" else "cliff_top")
	elif g in WALLS:
		var below := glyph(rows, x, y + 1)
		if below != "" and not below in WALLS:
			_put(tiles, x, y, "wall_shelf" if g == "w" else "wall_face")
		else:
			_put(tiles, x, y, "wall_top")
	elif g == "T":
		for ty in 2:
			for tx in 2:
				_put(tiles, x + tx, y + ty, "tree_%d_%d" % [tx, ty])
	elif HOUSES.has(g):
		for ty in HOUSE_SIZE.y:
			for tx in HOUSE_SIZE.x:
				_put(tiles, x + tx, y + ty, "house_%s_%d_%d" % [HOUSES[g], tx, ty])
		out["doors"].append(Vector2i(x, y) + HOUSE_DOOR)
	elif g == "K":
		_put(tiles, x, y, "table_l")
		_put(tiles, x + 1, y, "table_r")
	elif g == "D":
		_put(tiles, x, y, "bed_t")
		_put(tiles, x, y + 1, "bed_b")
	else:
		var ground := "floor" if indoor else ("grass_a" if not _near(rows, x, y, "a") else _ash(x, y))
		_put(tiles, x, y, "dfloor" if dungeon else ground)   # actors/objects on plain ground (ash next to ash)


# Ignis ground: plain ash with an ember-flecked cell here and there (a fixed pattern, so rebuilds look the same).
static func _ash(x: int, y: int) -> String:
	return "ash_b" if (x * 7 + y * 13) % 5 == 0 else "ash"


# True if one of the four neighbours of (x, y) is glyph `g`.
static func _near(rows: Array, x: int, y: int, g: String) -> bool:
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if glyph(rows, x + d.x, y + d.y) == g:
			return true
	return false


# The ice rod: turn the lava cell under `world_pos` (in any built area) into walkable crust for `seconds`, or keep
# an existing crust frozen that long again. Returns true if the cell was lava or crust.
static func freeze_at(tree: SceneTree, world_pos: Vector2, seconds: float) -> bool:
	for node in tree.get_nodes_in_group("terrain"):
		var tiles := node as TileMapLayer
		if tiles == null or not tiles.is_inside_tree():
			continue
		var cell := tiles.local_to_map(tiles.to_local(world_pos))
		var key := "%d:%d,%d" % [tiles.get_instance_id(), cell.x, cell.y]
		var td := tiles.get_cell_tile_data(cell)
		if td != null and bool(td.get_custom_data("lava")):
			_crust_under[key] = tiles.get_cell_atlas_coords(cell)
			tiles.set_cell(cell, 0, _cells["crust"])
		elif not (_crust_under.has(key) and tiles.get_cell_atlas_coords(cell) == _cells["crust"]):
			continue
		var gen := int(_crust_gen.get(key, 0)) + 1
		_crust_gen[key] = gen
		tree.create_timer(seconds, false, true).timeout.connect(func() -> void:
			if int(_crust_gen.get(key, 0)) != gen:
				return                                    # frozen again since: a later timer thaws it
			if is_instance_valid(tiles) and tiles.get_cell_atlas_coords(cell) == _cells["crust"]:
				tiles.set_cell(cell, 0, _crust_under[key])
			_crust_under.erase(key)
			_crust_gen.erase(key))
		return true
	return false


# Nine-slice piece name for a band of `same` glyphs: the lip faces the neighbours that differ.
# Off-area neighbours count as the same terrain, so roads and water run on seamlessly into the next area.
static func _nine(rows: Array, x: int, y: int, same: String, base: String) -> String:
	var l := _differs(rows, x - 1, y, same)
	var r := _differs(rows, x + 1, y, same)
	var u := _differs(rows, x, y - 1, same)
	var d := _differs(rows, x, y + 1, same)
	var dx := 0 if l == r else (-1 if l else 1)
	var dy := 0 if u == d else (-1 if u else 1)
	return "%s_%d_%d" % [base, dx, dy]


static func _differs(rows: Array, x: int, y: int, same: String) -> bool:
	var g := glyph(rows, x, y)
	return g != "" and g != same


# True if the terrain cell under `world_pos` carries `flag` ("ledge", "door", "exit") in any terrain layer.
static func flag_at(tree: SceneTree, world_pos: Vector2, flag: String) -> bool:
	for n in tree.get_nodes_in_group("terrain"):
		var tl := n as TileMapLayer
		if tl == null or not tl.is_inside_tree():
			continue
		var cell := tl.local_to_map(tl.to_local(world_pos))
		var td := tl.get_cell_tile_data(cell)
		if td != null and bool(td.get_custom_data(flag)):
			return true
	return false
