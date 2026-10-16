# File: World.gd
# Description: The game world: loads generated areas with their villagers and signs, follows Joe with a clamped camera, scrolls screen-to-screen at area edges (ALttP), fades through house doors, and hosts the HUD, dialogue box, pause/item menus, Game Over and saving.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 2.0.0
class_name World
extends Node2D
## Areas come from src/world/areas/*.json (written by tools/gen_areas.py - never edit them by hand).
## Every overworld area sits at its global tile position, so Joe's coordinates stay continuous across an edge:
## when his feet leave the current area, the neighbour is built, the camera slides over while Joe takes a few
## steps in, and the old area is freed. Doors and exit mats fade to black and move Joe between areas.
## Only the current area exists in the tree (enemies and cut bushes come back when an area is re-entered).
## Talking, the pause and item menus and Game Over pause the tree; their CanvasLayers keep processing.
## A save stores the area and the point where Joe entered it; the title screen hands a loaded save over through
## SaveGame.pending, applied here before the first area is built.

signal area_entered(area_id: String)

const AREA_DIR := "res://src/world/areas/"
const PLAYER_SCENE := preload("res://src/player/Player.tscn")
const TITLE_SCENE := "res://src/ui/TitleScreen.tscn"
const TILE := 16
const VIEW := Vector2(384, 216)
const SCROLL_TIME := 0.6                 # seconds the camera takes to slide to the next area
const SCROLL_PUSH := 14.0                # px Joe walks into the new area during the slide
const FADE_TIME := 0.22                  # door fade out / in
const RESPAWN_DELAY := 1.5               # s between Joe falling and the Game Over screen
const BOX_TOP_BELOW := 0.55              # Joe below this fraction of the view height -> dialogue box at the top
const BLACK := Color(0.0, 0.0, 0.0, 1.0)
const FACINGS := {"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT, "right": Vector2i.RIGHT}

var start_area := ""
var areas: Dictionary = {}               # id -> area data (from JSON)
var current: Dictionary = {}             # {id, data, tiles, actors, rect, bushes, pots, enemies, origin}
var player: Player
var camera: Camera2D
var hud: Hud
var dialogue: DialogueBox
var pause_menu: PauseMenu
var item_menu: ItemMenu
var game_over: GameOver
var talking: Node2D = null               # the villager or sign in the current conversation
var transitioning := false
var transitions := 0                     # screen scrolls + door warps done (tests)
var entry_point := Vector2.ZERO          # where Joe entered the current area (respawn point, save point)
var entry_facing := Vector2i.DOWN
var deaths := 0

var _ground: Node2D
var _actors: Node2D
var _fade: ColorRect
var _area_override := ""                 # tests may start somewhere else
var _spawn_override = null
var _facing_override := Vector2i.DOWN
var _save_to_apply: Dictionary = {}


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
	player.talk_requested.connect(_on_talk_requested)
	hud = Hud.new()
	add_child(hud)
	player.health_changed.connect(hud.set_health)
	hud.set_health(player.health.current_health, player.health.max_health)
	area_entered.connect(func(aid: String) -> void: hud.show_caption(String(areas[aid]["name"]).to_upper()))
	_build_overlays()
	_take_pending_save()
	var first := _area_override if _area_override != "" else start_area
	_enter(first, _spawn_override if _spawn_override != null else _spawn_point(first), _facing_override)
	if not _save_to_apply.is_empty():
		_set_hearts(int(_save_to_apply.get("hp", PlayerTuning.MAX_HP)), int(_save_to_apply.get("max_hp", PlayerTuning.MAX_HP)))
		_save_to_apply = {}


func _build_overlays() -> void:
	dialogue = DialogueBox.new()
	add_child(dialogue)
	dialogue.closed.connect(_on_dialogue_closed)
	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	pause_menu.save_requested.connect(func() -> void: pause_menu.show_saved(save_game()))
	pause_menu.quit_requested.connect(func() -> void:
		save_game()
		quit_to_title())
	item_menu = ItemMenu.new()
	add_child(item_menu)
	game_over = GameOver.new()
	add_child(game_over)
	game_over.picked.connect(_on_game_over_picked)
	var layer := CanvasLayer.new()
	layer.layer = UiTheme.LAYER_FADE
	add_child(layer)
	_fade = UiTheme.overlay(BLACK)
	_fade.modulate.a = 0.0
	layer.add_child(_fade)


# A save handed over by the title screen (CONTINUE): restore the global state and start where it was made.
func _take_pending_save() -> void:
	var data := SaveGame.pending
	SaveGame.pending = {}
	if data.is_empty() or not areas.has(String(data.get("area", ""))):
		return
	GameState.restore(data.get("state", {}))
	var pos: Array = data.get("pos", [])
	var f: Array = data.get("facing", [0, 1])
	_area_override = String(data["area"])
	_spawn_override = Vector2(float(pos[0]), float(pos[1])) if pos.size() == 2 else _spawn_point(_area_override)
	_facing_override = Vector2i(int(f[0]), int(f[1]))
	_save_to_apply = data


func _set_hearts(current: int, maximum: int) -> void:
	player.health.max_health = maximum
	player.health.current_health = clampi(current, 1, maximum)
	player.health.health_changed.emit(player.health.current_health, maximum)


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
	var origin := origin_of(area_id)
	for n in data.get("npcs", []):
		var npc := Npc.new()
		npc.setup(String(n["id"]), String(n["facing"]), bool(n.get("across", false)))
		npc.position = cell_feet(area_id, n["cell"])
		actors.add_child(npc)
	for sgn in data.get("signs", []):
		var post := SignPost.new()
		post.setup(String(sgn["text"]))
		post.position = origin + (Vector2(float(sgn["cell"][0]), float(sgn["cell"][1])) + Vector2(0.5, 0.5)) * TILE
		actors.add_child(post)
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
	entry_facing = facing
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
	entry_facing = Vector2i(dir)
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


# --- talking ----------------------------------------------------------------------------------------

func _on_talk_requested(target: Node2D) -> void:
	if transitioning or dialogue.is_open or not is_instance_valid(target):
		return
	var key := String(target.call("talk", player.global_position))
	var pages := DialogueData.pages_for(key, GameState)
	if pages.is_empty():
		return
	talking = target
	# ALttP: the box goes to the top when Joe stands in the lower part of the screen.
	var on_screen := player.global_position - (camera.global_position - VIEW / 2.0)
	dialogue.open(pages, DialogueData.speaker(key), box_at_top(on_screen))


# True when Joe's on-screen position is low enough that the dialogue box should go to the top.
func box_at_top(screen_pos: Vector2) -> bool:
	return screen_pos.y > VIEW.y * BOX_TOP_BELOW


func _on_dialogue_closed() -> void:
	if is_instance_valid(talking):
		talking.call("rest")
	talking = null
	player.freeze(PlayerTuning.TALK_COOLDOWN)


# --- menus ------------------------------------------------------------------------------------------

# True when nothing else owns the screen (no scroll, fade, conversation, menu or death in progress).
func can_open_menu() -> bool:
	return not transitioning and not dialogue.is_open and not pause_menu.is_open and not item_menu.is_open \
			and not game_over.is_open and not player.is_dead()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not can_open_menu():
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		pause_menu.open()
	elif event.is_action_pressed("inventory"):
		get_viewport().set_input_as_handled()
		item_menu.open()


# Write the save file: the current area, where Joe entered it, his hearts and the GameState snapshot.
func save_game() -> bool:
	var data := SaveGame.capture(current_id(), entry_point, entry_facing, player.health.current_health,
			player.health.max_health, GameState)
	return SaveGame.write(data)


func quit_to_title() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE)


# --- death ----------------------------------------------------------------------------------------

# Joe fell: after a short beat the Game Over screen offers to continue (and save, or quit).
func _on_player_died() -> void:
	deaths += 1
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	if is_instance_valid(player) and player.is_dead():
		game_over.open()


# Continue = Joe gets back up where he entered this area with full hearts (the area is rebuilt fresh).
# The save variants write the file first (with Joe already back on his feet).
func _on_game_over_picked(choice: int) -> void:
	player.revive(entry_point)
	if choice == GameOver.SAVE_CONTINUE or choice == GameOver.SAVE_QUIT:
		save_game()
		if choice == GameOver.SAVE_QUIT:
			quit_to_title()
			return
	_enter(current_id(), entry_point, entry_facing)


func current_id() -> String:
	return String(current.get("id", ""))
