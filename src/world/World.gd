# File: World.gd
# Description: The game world: loads generated areas, follows Joe with a clamped camera, scrolls screen-to-screen at area edges (ALttP), fades through house doors, hosts the HUD and respawns.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
class_name World
extends Node2D
## Areas come from src/world/areas/*.json (written by tools/gen_areas.py - never edit them by hand).
## Every overworld area sits at its global tile position, so Joe's coordinates stay continuous across an edge:
## when his feet leave the current area, the neighbour is built, the camera slides over while Joe takes a few
## steps in, and the old area is freed. Doors and exit mats fade to black and move Joe between areas.
## Only the current area exists in the tree (enemies and cut bushes come back when an area is re-entered).

signal area_entered(area_id: String)

const AREA_DIR := "res://src/world/areas/"
const PLAYER_SCENE := preload("res://src/player/Player.tscn")
const TILE := 16
const VIEW := Vector2(384, 216)
const SCROLL_TIME := 0.6                 # seconds the camera takes to slide to the next area
const SCROLL_PUSH := 14.0                # px Joe walks into the new area during the slide
const FADE_TIME := 0.22                  # door fade out / in
const RESPAWN_DELAY := 1.5
const BLACK := Color(0.0, 0.0, 0.0, 1.0)
const FACINGS := {"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT, "right": Vector2i.RIGHT}

var start_area := ""
var areas: Dictionary = {}               # id -> area data (from JSON)
var current: Dictionary = {}             # {id, data, tiles, actors, rect, bushes, pots, enemies, origin}
var player: Player
var camera: Camera2D
var hud: Hud
var transitioning := false
var transitions := 0                     # screen scrolls + door warps done (tests)
var entry_point := Vector2.ZERO          # where Joe entered the current area (respawn point)
var deaths := 0

var _ground: Node2D
var _actors: Node2D
var _fade: ColorRect
var _area_override := ""                 # tests may start somewhere else
var _spawn_override = null


func _ready() -> void:
	_load_index()
	_ground = Node2D.new()
	_ground.name = "Ground"
	add_child(_ground)
	_actors = Node2D.new()
	_actors.name = "Actors"
	_actors.y_sort_enabled = true
	add_child(_actors)
	camera = Camera2D.new()
	camera.name = "Camera"
	add_child(camera)
	camera.make_current()
	player = PLAYER_SCENE.instantiate()
	_actors.add_child(player)
	player.died.connect(_on_player_died)
	hud = Hud.new()
	add_child(hud)
	player.health_changed.connect(hud.set_health)
	hud.set_health(player.health.current_health, player.health.max_health)
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = BLACK
	_fade.size = VIEW
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	var first := _area_override if _area_override != "" else start_area
	_enter(first, _spawn_override if _spawn_override != null else _spawn_point(first))


# Tests call this before adding the World to the tree to start in a given area at a given feet position.
func start_at(area_id: String, feet: Vector2) -> void:
	_area_override = area_id
	_spawn_override = feet


func _load_index() -> void:
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(AREA_DIR + "index.json"))
	start_area = String(index["start"])
	for aid in index["areas"]:
		areas[aid] = JSON.parse_string(FileAccess.get_file_as_string(AREA_DIR + String(aid) + ".json"))


# --- geometry ------------------------------------------------------------------------

func origin_of(area_id: String) -> Vector2:
	var o: Array = areas[area_id]["origin_tiles"]
	return Vector2(float(o[0]), float(o[1])) * TILE


func rect_of(area_id: String) -> Rect2:
	var rows: Array = areas[area_id]["rows"]
	return Rect2(origin_of(area_id), Vector2(String(rows[0]).length(), rows.size()) * TILE)


# Feet position (global) for a cell of an area.
func cell_feet(area_id: String, cell: Array) -> Vector2:
	return origin_of(area_id) + Vector2(float(cell[0]) * TILE + TILE / 2.0, (float(cell[1]) + 1.0) * TILE - 2.0)


func _spawn_point(area_id: String) -> Vector2:
	var rows: Array = areas[area_id]["rows"]
	for y in rows.size():
		var x := String(rows[y]).find("P")
		if x >= 0:
			return cell_feet(area_id, [x, y])
	return rect_of(area_id).get_center()


# The overworld area containing a global point, or "".
func overworld_at(p: Vector2) -> String:
	for aid in areas:
		if areas[aid]["kind"] == "overworld" and rect_of(aid).has_point(p):
			return aid
	return ""


# --- building ----------------------------------------------------------------------------

func _build(area_id: String) -> Dictionary:
	var data: Dictionary = areas[area_id]
	var actors := Node2D.new()
	actors.name = "Area_" + area_id
	actors.y_sort_enabled = true
	_actors.add_child(actors)
	var built := AreaBuilder.build(data["rows"], actors, data["kind"] == "interior", true, origin_of(area_id))
	_ground.add_child(built["tiles"])
	for e in built["enemies"]:
		e.player = player
	return {"id": area_id, "data": data, "tiles": built["tiles"], "actors": actors, "rect": rect_of(area_id),
			"bushes": built["bushes"], "pots": built["pots"], "enemies": built["enemies"]}


func _free(rec: Dictionary) -> void:
	if rec.is_empty():
		return
	rec["tiles"].queue_free()
	rec["actors"].queue_free()


func _enter(area_id: String, feet: Vector2, facing: Vector2i = Vector2i.DOWN) -> void:
	_free(current)
	current = _build(area_id)
	if player.health.is_alive():
		_place_player(feet, facing)
	else:
		player.revive(feet)
	player.facing = facing
	entry_point = feet
	_snap_camera()
	area_entered.emit(area_id)


func _place_player(feet: Vector2, facing: Vector2i) -> void:
	player.global_position = feet
	player.velocity = Vector2.ZERO
	player.facing = facing
	player.fsm.transition_to("idle")


# --- camera ----------------------------------------------------------------------------------

# Camera centre for Joe at `p` inside `rect`: follow him, clamped so the view never leaves the area
# (an area narrower than the view is centred, which frames the small house interiors).
func camera_target(p: Vector2, rect: Rect2) -> Vector2:
	var half := VIEW / 2.0
	var c := Vector2.ZERO
	for i in 2:
		var lo := rect.position[i] + half[i]
		var hi := rect.end[i] - half[i]
		c[i] = (rect.position[i] + rect.end[i]) / 2.0 if lo > hi else clampf(p[i], lo, hi)
	return c.round()


func _snap_camera() -> void:
	camera.global_position = camera_target(player.global_position + PlayerTuning.BODY_CENTER, current["rect"])
	camera.reset_smoothing()


func _process(_delta: float) -> void:
	if not transitioning and not current.is_empty():
		camera.global_position = camera_target(player.global_position + PlayerTuning.BODY_CENTER, current["rect"])


# --- edges and doors ---------------------------------------------------------------------------

func _physics_process(_delta: float) -> void:
	if transitioning or current.is_empty() or player.is_dead() or player.is_hopping():
		return
	var feet := player.global_position
	var data: Dictionary = current["data"]
	if data["kind"] == "overworld" and not current["rect"].has_point(feet):
		var next := overworld_at(feet)
		if next != "":
			_scroll_to(next)
		return
	var cell := Vector2i(((feet - current["rect"].position) / TILE).floor())
	for d in data["doors"]:
		if cell == Vector2i(int(d["cell"][0]), int(d["cell"][1])) and player.facing == Vector2i.UP:
			_warp(String(d["to"]), cell_feet(String(d["to"]), d["spawn_cell"]), FACINGS[String(d["facing"])])
			return
	for e in data["exits"]:
		for c in e["cells"]:
			if cell == Vector2i(int(c[0]), int(c[1])) and player.facing == Vector2i.DOWN:
				_warp(String(e["to"]), cell_feet(String(e["to"]), e["spawn_cell"]), FACINGS[String(e["facing"])])
				return


# ALttP screen scroll: freeze everything, build the neighbour, slide the camera while Joe steps in.
func _scroll_to(next_id: String) -> void:
	transitioning = true
	var old := current
	old["actors"].process_mode = Node.PROCESS_MODE_DISABLED
	var dir := _edge_direction(old["rect"], player.global_position)
	var to_feet := player.global_position + dir * SCROLL_PUSH
	current = _build(next_id)
	current["actors"].process_mode = Node.PROCESS_MODE_DISABLED
	player.freeze(SCROLL_TIME * 4.0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(camera, "global_position", camera_target(to_feet + PlayerTuning.BODY_CENTER, current["rect"]), SCROLL_TIME)
	tw.tween_property(player, "global_position", to_feet, SCROLL_TIME)
	await tw.finished
	_free(old)
	current["actors"].process_mode = Node.PROCESS_MODE_INHERIT
	player.unfreeze()
	entry_point = player.global_position
	transitions += 1
	transitioning = false
	area_entered.emit(next_id)


# Unit vector pointing out of `rect` across the edge `p` has crossed.
func _edge_direction(rect: Rect2, p: Vector2) -> Vector2:
	if p.x < rect.position.x:
		return Vector2.LEFT
	if p.x >= rect.end.x:
		return Vector2.RIGHT
	if p.y < rect.position.y:
		return Vector2.UP
	return Vector2.DOWN


# Door / exit-mat warp: fade to black, swap areas, place Joe, fade back in.
func _warp(area_id: String, feet: Vector2, facing: Vector2i) -> void:
	transitioning = true
	player.freeze(FADE_TIME * 6.0)
	Audio.sfx("door")
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, FADE_TIME)
	await tw.finished
	_enter(area_id, feet, facing)
	var tw2 := create_tween()
	tw2.tween_property(_fade, "modulate:a", 0.0, FADE_TIME)
	await tw2.finished
	player.unfreeze()
	transitions += 1
	transitioning = false


# --- death ----------------------------------------------------------------------------------------

# Joe fell: after a short beat he gets back up where he entered this area (Game Over screen: Phase 4).
func _on_player_died() -> void:
	deaths += 1
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	if is_instance_valid(player):
		player.revive(entry_point)
		_snap_camera()


func current_id() -> String:
	return String(current.get("id", ""))
