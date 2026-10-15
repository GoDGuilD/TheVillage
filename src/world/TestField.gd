# File: TestField.gd
# Description: Playground meadow (2x2 screens) built from an ASCII layout: tiles, trees, rocks, bushes, pots, enemies, Joe, HUD, respawn.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 3.0.0
extends Node2D
## Layout glyphs: '.' grass, ',' tufted grass, '*' flowers, '#' dirt path (edges chosen automatically),
## 'R' rock (solid), 'T' top-left cell of a 2x2 tree with 'x' on its other three cells, 'B' bush, 'O' pot,
## 'Z' slime, 'G' guard, 'Q' rock-spitter, 'P' Joe's spawn.
## Tests may assign `layout` before adding the node to the tree to build a custom arena.
## Tiles and actors are painted by AreaBuilder (same glyphs as the real areas).

const TILE := 16
const PLAYER_SCENE := preload("res://src/player/Player.tscn")
const RESPAWN_DELAY := 1.5               # seconds between Joe falling and getting back up at the spawn

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


func _ready() -> void:
	actors = Node2D.new()
	actors.name = "Actors"
	actors.y_sort_enabled = true           # Joe and props draw in feet order
	var built := AreaBuilder.build(layout, actors, false, spawn_enemies)
	tiles = built["tiles"]
	add_child(tiles)
	add_child(actors)
	bushes = built["bushes"]
	pots = built["pots"]
	enemies = built["enemies"]
	if built["spawn"] != null:
		_spawn_player(built["spawn"])
	for e in enemies:
		e.player = player
	hud = Hud.new()
	add_child(hud)
	if player != null:
		player.health_changed.connect(hud.set_health)
		hud.set_health(player.health.current_health, player.health.max_health)
		player.died.connect(_on_player_died)


func _spawn_player(at: Vector2) -> void:
	player = PLAYER_SCENE.instantiate()
	spawn_point = at
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
