# File: TestField.gd
# Description: Playground meadow (2x2 screens) built from an ASCII layout: tiles, trees, rocks, bushes, pots, enemies, Joe, HUD, respawn.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 2.0.0
extends Node2D
## Layout glyphs: '.' grass, ',' tufted grass, '*' flowers, '#' dirt path (edges chosen automatically),
## 'R' rock (solid), 'T' top-left cell of a 2x2 tree with 'x' on its other three cells, 'B' bush, 'O' pot,
## 'Z' slime, 'G' guard, 'Q' rock-spitter, 'P' Joe's spawn.
## Tests may assign `layout` before adding the node to the tree to build a custom arena.
## The TileSet is built at runtime from the atlas manifest written by tools/gen_tiles.py.

const TILE := 16
const ATLAS_TEX := preload("res://assets/tiles/overworld_light.png")
const ATLAS_JSON := "res://assets/tiles/overworld_light.json"
const PLAYER_SCENE := preload("res://src/player/Player.tscn")
const ENEMY_SCRIPTS := {"Z": preload("res://src/enemies/Slime.gd"), "G": preload("res://src/enemies/Guard.gd"),
		"Q": preload("res://src/enemies/Spitter.gd")}
const RESPAWN_DELAY := 1.5               # seconds between Joe falling and getting back up at the spawn
const LAYER_WORLD := 1
const PATH := "#"

const DEFAULT_LAYOUT := [
	"TxTxTxTxTxTxTxTxTxTxTxTxTxTxTxTxTxTxTxTxTxTxTxTx",
	"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
	"Tx,,.......,.....,....###....,.,...,,,,,.,....Tx",
	"xx........,.........*,###.,...Z,...,..,....,..xx",
	"Tx.,..Tx....Z.,.,.....###..........,BB.*....,.Tx",
	"xx....xx....,.,BBB..,.###,.....,Tx........*...xx",
	"Tx,...*.Tx,.,.,B.B....###,,.....xxG.*.,...,,,.Tx",
	"xx,.,..,xx......*,,,,,###.,...,..,.........*..xx",
	"Tx.,.,.,.,,.,.....,,.,###....,.....,..Tx.,....Tx",
	"xx.....,..RR.,,...,...###*OO,,...,*.,.xx....,.xx",
	"Tx...Q.,.....,...*...,###......,.,R,..*.,..,.,Tx",
	"xx.......,,.,.....,...###..,.,..,...,.,.......xx",
	"Tx############################################Tx",
	"xx############################################xx",
	"Tx############################################Tx",
	"xx....,,....,..,..,..,###,...*.,,........,B.*,xx",
	"Tx...,..,..,..**....P.###....*,....,......B...Tx",
	"xx,.....R........OOO..###.*.BBB........,.,..,.xx",
	"Tx,...,*.,......,,....###..,..,........,Z,.*.,Tx",
	"xx,.....,...Tx...,....###..........,,....,.,..xx",
	"Tx.,,BB.....xx..,....,###..,..Tx....*.....,...Tx",
	"xx............,..*....###,..*.xx...,..,.Tx...,xx",
	"Tx....,...,....,..BB*,###.*,.,....,.....xx....Tx",
	"xx*.......G...........###,.R........,..,,....,xx",
	"Tx.,,.,,.........*.,.,###,..,,........Q,...,..Tx",
	"xx,.....,.,.,.........###,...,.,.......,,...,.xx",
	"TxTxTxTxTxTxTxTxTxTxTxTxTxTxTxTxTxTxTxTxTxTxTxTx",
	"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
]
# Glyph -> atlas cell name for plain ground.
const GROUND := {".": "grass_a", ",": "grass_b", "*": "flowers", "R": "rock"}

var layout: Array = DEFAULT_LAYOUT
var spawn_enemies := true                # tests may build arenas without the layout's enemies
var tiles: TileMapLayer
var actors: Node2D
var player: Player
var hud: Hud
var bushes: Array = []
var pots: Array = []
var enemies: Array = []
var spawn_point := Vector2.ZERO
var deaths := 0

var _cells: Dictionary = {}               # atlas cell name -> Vector2i


func _ready() -> void:
	tiles = TileMapLayer.new()
	tiles.name = "Tiles"
	tiles.tile_set = _build_tileset()
	add_child(tiles)
	actors = Node2D.new()
	actors.name = "Actors"
	actors.y_sort_enabled = true           # Joe and bushes draw in feet order
	add_child(actors)
	_paint()
	for e in enemies:
		e.player = player
	hud = Hud.new()
	add_child(hud)
	if player != null:
		player.health_changed.connect(hud.set_health)
		hud.set_health(player.health.current_health, player.health.max_health)
		player.died.connect(_on_player_died)


# TileSet from the atlas manifest: one 16x16 tile per named cell, full-square collision on solid ones.
func _build_tileset() -> TileSet:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ATLAS_JSON))
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, LAYER_WORLD)
	ts.set_physics_layer_collision_mask(0, 0)
	var src := TileSetAtlasSource.new()
	src.texture = ATLAS_TEX
	src.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(src, 0)
	var half := TILE / 2.0
	var square := PackedVector2Array([Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)])
	for cell_name in manifest["cells"]:
		var info: Dictionary = manifest["cells"][cell_name]
		var at := Vector2i(int(info["cell"][0]), int(info["cell"][1]))
		_cells[cell_name] = at
		src.create_tile(at)
		if info["solid"]:
			var td := src.get_tile_data(at, 0)
			td.add_collision_polygon(0)
			td.set_collision_polygon_points(0, 0, square)
	return ts


func _glyph(x: int, y: int) -> String:
	if y < 0 or y >= layout.size():
		return ""
	var row: String = layout[y]
	if x < 0 or x >= row.length():
		return ""
	return row[x]


func _put_tile(x: int, y: int, cell_name: String) -> void:
	tiles.set_cell(Vector2i(x, y), 0, _cells[cell_name])


func _paint() -> void:
	for y in layout.size():
		var row: String = layout[y]
		for x in row.length():
			var g := row[x]
			if g == "x":
				continue                                   # filled by its tree's anchor
			if g == "T":
				for ty in 2:
					for tx in 2:
						_put_tile(x + tx, y + ty, "tree_%d_%d" % [tx, ty])
			elif g == PATH:
				_put_tile(x, y, _path_piece(x, y))
			else:
				_put_tile(x, y, GROUND.get(g, "grass_a"))
			if g == "B":
				_add_bush(x, y)
			elif g == "O":
				_add_pot(x, y)
			elif ENEMY_SCRIPTS.has(g) and spawn_enemies:
				_add_enemy(g, x, y)
			elif g == "P":
				_spawn_player(x, y)


# Pick the nine-slice piece whose grassy lips face the non-path neighbours.
func _path_piece(x: int, y: int) -> String:
	var l := _glyph(x - 1, y) != PATH
	var r := _glyph(x + 1, y) != PATH
	var u := _glyph(x, y - 1) != PATH
	var d := _glyph(x, y + 1) != PATH
	var dx := 0 if l == r else (-1 if l else 1)
	var dy := 0 if u == d else (-1 if u else 1)
	return "path_%d_%d" % [dx, dy]


func _add_bush(x: int, y: int) -> void:
	var b := Bush.new()
	b.position = _cell_center(x, y)
	actors.add_child(b)
	bushes.append(b)


func _add_pot(x: int, y: int) -> void:
	var p := Pot.new()
	p.position = _cell_center(x, y)
	actors.add_child(p)
	pots.append(p)


func _add_enemy(glyph: String, x: int, y: int) -> void:
	var e: BaseEnemy = ENEMY_SCRIPTS[glyph].new()
	e.position = Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE - 2)
	actors.add_child(e)
	enemies.append(e)


func _cell_center(x: int, y: int) -> Vector2:
	return Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)


func _spawn_player(x: int, y: int) -> void:
	player = PLAYER_SCENE.instantiate()
	spawn_point = Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE - 2)
	player.position = spawn_point
	actors.add_child(player)
	var cam := Camera2D.new()
	cam.name = "Camera"
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = field_size().x
	cam.limit_bottom = field_size().y
	player.add_child(cam)


# Field size in pixels.
func field_size() -> Vector2i:
	return Vector2i(String(layout[0]).length() * TILE, layout.size() * TILE)


# Joe fell: after a short beat he gets back up at the spawn with full hearts (Game Over screen: Phase 4).
func _on_player_died() -> void:
	deaths += 1
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	if is_instance_valid(player):
		player.revive(spawn_point)
