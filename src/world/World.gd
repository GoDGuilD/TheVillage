# File: World.gd
# Description: The game world: loads generated areas with their villagers and signs, follows Joe with a clamped camera, scrolls screen-to-screen at area edges (ALttP), fades through house doors, and hosts the HUD, dialogue box, pause/item menus, Game Over and saving; builds chests, torches, cracked rocks, key blocks, heart pieces and shop wares and runs the item-get, shop and key sequences; dungeons: room scrolling, doors, room clearing, switches, push blocks, pits, the boss and its reward, the map; Act 1: rubble, the keep's seal gate and the ending; Act 2: the Dark World twins, dream rifts and the Moon Mirror; Umbra: hook posts, dark rooms, dimension crystals; Ignis: lava; Tempus: the tick clock, pegs.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-23
# Version: 6.2.0
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
## Opened chests, broken rocks, opened key blocks, taken heart pieces and sold-out wares are GameState flags named
## "<kind>:<area>:<x>,<y>" (wares: "ware:<id>"), so they survive area changes and saves.
## Dungeon rooms scroll into each other like overworld areas (same "group"). Doors read their state from flags:
## "door:<id>" (opened locked/big doors), the room flags "cleared:<room>" / "switch:<room>" (shutters), and the
## dungeon's "boss:<dungeon>" (the boss door shuts behind Joe until then).
## The Dark World twins share the Light World's coordinates (group "overworld_dark"), so a warp between the worlds
## keeps Joe's position: the Moon Mirror (Dark -> Light, bouncing back if that spot is solid, leaving a shimmer to
## return through) and the dream rifts (Light -> Dark, shown once Act 1 is over).

signal area_entered(area_id: String)

const AREA_DIR := "res://src/world/areas/"
const PLAYER_SCENE := preload("res://src/player/Player.tscn")
const TITLE_SCENE := "res://src/ui/TitleScreen.tscn"
const PICKUP_SCRIPT := preload("res://src/world/Pickup.gd")
const SHOP_CHOICES := ["BUY", "NO"]
const BOW_ARROWS := 10                   # the bow comes with a quiver
const CONTAINER_HP := 2                  # half-heart units a heart container adds
const DUNGEON_PUSH := 40.0               # px Joe walks into a dungeon room on a scroll (past the 2-tile wall)
const BOSS_REWARD_DELAY := 1.2           # s after the boss falls before the heart container appears
const REWARD_DROP := Vector2(0, 8)       # heart container position relative to the room's centre
const SEAL_DROP := Vector2(0, -24)       # the seal appears above it (not under Joe, who just took the heart)
const DARK_SMALL := preload("res://assets/sprites/world/darkness_small.png")      # dark rooms without the lantern
const DARK_LANTERN := preload("res://assets/sprites/world/darkness_lantern.png")  # ...and with it
const DARK_Z := 100                      # the darkness covers every actor (the HUD and boxes are CanvasLayers)
const TICK_TIME := 2.0                   # s between two ticks of Tempus's broken clock (tick blocks swap)
const GATE_FLAG := "keep:gate"           # the seal gate of Caver's keep is open
const ACT1_FLAG := "act1:done"
const ENDING_DELAY := 1.5                # s between the shade's fall and Caver's last words
const ACT2_FLAG := "act2:started"        # the Act 2 intro was shown
const DW_TINT := Color(0.78, 0.68, 0.92)  # Dark World actors (bushes, pots, enemies, villagers) take this tint
const DW_HP_FACTOR := 2                  # Dark World enemies are twice as tough
const WORLD_FADE := 0.18                 # mirror / rift fade out and in
const SOLID_PROBE := Vector2(0, -3)      # the point under Joe checked for a solid tile after a mirror warp
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
var map_screen: MapScreen
var end_card: EndCard
var endings := 0                         # act endings played (tests)
var world_warps := 0                     # mirror and rift warps done (tests)
var mirror_bounces := 0                  # mirror warps thrown back by a solid spot (tests)
var act2_spawn: Dictionary = {}          # {area, cell}: where Caver's spell drops Joe
var dungeons: Dictionary = {}            # dungeon id -> {name, seal, entrance, boss_room, boss_flag}
var falls := 0                           # pit falls (tests)
var darkness: Sprite2D                   # the night around Joe in a dark room (gen_umbra.py masks)
var tick_phase := 0                      # 0: amber tick blocks up, teal down; 1: the other way round
var ticks := 0                           # clock ticks so far (tests)
var _tick_left := TICK_TIME
var talking: Node2D = null               # the villager or sign in the current conversation
var item_gets := 0                       # item-get sequences run (tests)
var _after_dialogue := Callable()        # runs once the current box closes (gift hand-over, end of item-get)
var _offer: Node2D = null                # the ware Boni is offering
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
var _last_area := ""                     # the area before the current one (captions skip room-to-room moves)


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
	darkness = Sprite2D.new()
	darkness.name = "Darkness"
	darkness.z_index = DARK_Z
	darkness.visible = false
	add_child(darkness)
	player = PLAYER_SCENE.instantiate()
	_actors.add_child(player)
	player.died.connect(_on_player_died)
	player.talk_requested.connect(_on_talk_requested)
	player.item_collected.connect(func(kind: String) -> void: item_get(kind))
	player.fell.connect(_on_fell)
	player.mirror_requested.connect(_on_mirror)
	hud = Hud.new()
	add_child(hud)
	player.health_changed.connect(hud.set_health)
	hud.set_health(player.health.current_health, player.health.max_health)
	area_entered.connect(_on_area_entered)
	_build_overlays()
	_take_pending_save()
	var first := _area_override if _area_override != "" else start_area
	_enter(first, _spawn_override if _spawn_override != null else _spawn_point(first), _facing_override)
	if not _save_to_apply.is_empty():
		_set_hearts(int(_save_to_apply.get("hp", PlayerTuning.MAX_HP)), int(_save_to_apply.get("max_hp", PlayerTuning.MAX_HP)))
		_save_to_apply = {}
	# Act 2 opens the first time a game continues after the end of Act 1.
	if GameState.has_flag(ACT1_FLAG) and not GameState.has_flag(ACT2_FLAG):
		GameState.set_flag(ACT2_FLAG)
		say.call_deferred("act2_intro")


func _build_overlays() -> void:
	dialogue = DialogueBox.new()
	add_child(dialogue)
	dialogue.closed.connect(_on_dialogue_closed)
	dialogue.answered.connect(_on_answered)
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
	map_screen = MapScreen.new()
	add_child(map_screen)
	end_card = EndCard.new()
	add_child(end_card)
	end_card.finished.connect(_on_end_card_finished)
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
	dungeons = index.get("dungeons", {})
	act2_spawn = index.get("act2_spawn", {})
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
	return area_at(p, "overworld")


# Areas that scroll into each other: the overworld, or the rooms of one dungeon. Interiors have no group ("").
func group_of(area_id: String) -> String:
	var a: Dictionary = areas[area_id]
	if a["kind"] == "overworld":
		return "overworld_dark" if is_dark(area_id) else "overworld"
	return String(a.get("dungeon", ""))


func is_dark(area_id: String) -> bool:
	return String(areas[area_id].get("world", "")) == "dark"


# The area of `group` containing a global point, or "".
func area_at(p: Vector2, group: String) -> String:
	for aid in areas:
		if group_of(aid) == group and rect_of(aid).has_point(p):
			return aid
	return ""


func dungeon_of(area_id: String) -> String:
	return String(areas[area_id].get("dungeon", ""))


# --- building ----------------------------------------------------------------------------

func _build(area_id: String) -> Dictionary:
	var data: Dictionary = areas[area_id]
	var actors := Node2D.new()
	actors.name = "Area_" + area_id
	actors.y_sort_enabled = true
	_actors.add_child(actors)
	var dark := is_dark(area_id)
	var built := AreaBuilder.build(data["rows"], actors, data["kind"] == "interior", true, origin_of(area_id),
			data["kind"] == "dungeon", dark)
	if dark:
		actors.modulate = DW_TINT
		for e in built["enemies"]:
			e.health.max_health *= DW_HP_FACTOR
			e.health.current_health = e.health.max_health
	_ground.add_child(built["tiles"])
	var boss_flag := String(data.get("boss_flag", ""))
	for e in built["enemies"].duplicate():
		e.player = player
		if e.get("is_boss"):
			if GameState.has_flag(boss_flag):
				built["enemies"].erase(e)                 # already beaten: the room stays empty
				e.queue_free()
			else:
				e.defeated.connect(func(_at: Vector2) -> void: _on_boss_defeated(area_id))
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
	for o in data.get("objects", []):
		_build_object(area_id, o, actors)
	for w in data.get("wares", []):
		var ware_id := String(w["ware"])
		if bool(ItemDB.WARES[ware_id]["once"]) and GameState.has_flag("ware:" + ware_id):
			continue
		var item := ShopItem.new()
		item.setup(ware_id)
		item.position = origin + (Vector2(float(w["cell"][0]), float(w["cell"][1])) + Vector2(0.5, 0.5)) * TILE
		actors.add_child(item)
	var rec := {"id": area_id, "data": data, "tiles": built["tiles"], "actors": actors, "rect": rect_of(area_id),
			"bushes": built["bushes"], "pots": built["pots"], "enemies": built["enemies"],
			"tick_blocks": built["tick_blocks"], "pegs": built["pegs"]}
	_apply_ticks(rec)
	if boss_flag != "" and GameState.has_flag(boss_flag):
		_spawn_boss_reward(rec)                           # came back before taking the reward
	return rec


# One chest / torch / cracked rock / key block / heart piece from the area data (skipped once used up).
func _build_object(area_id: String, o: Dictionary, actors: Node2D) -> void:
	var cell: Array = o["cell"]
	var at := origin_of(area_id) + (Vector2(float(cell[0]), float(cell[1])) + Vector2(0.5, 0.5)) * TILE
	var flag := object_flag(String(o["kind"]), area_id, cell)
	var node: Node2D = null
	match String(o["kind"]):
		"chest", "big_chest":
			var chest: Chest = BigChest.new() if o["kind"] == "big_chest" else Chest.new()
			var reveal := String(o.get("reveal", ""))
			var reveal_flag := String(o.get("flag", ""))
			var concealed := reveal != "" and not (reveal == "switch" and GameState.has_flag(reveal_flag))
			chest.setup(String(o["item"]), int(o.get("amount", 1)), flag, GameState.has_flag(flag), concealed)
			chest.reveal_by = reveal
			chest.reveal_flag = reveal_flag
			if o["kind"] == "big_chest":
				at += Vector2(TILE / 2.0, 0)                # centred on its two cells
			node = chest
		"door":
			var door := Door.new()
			var dtype := String(o["type"])
			var when := String(o.get("when", ""))
			var opened := true if dtype == "boss" else (GameState.has_flag(when) if dtype == "shutter"
					else GameState.has_flag("door:" + String(o["id"])))
			door.setup(String(o["id"]), dtype, String(o["dir"]), when, opened)
			at += Vector2(TILE / 2.0, TILE / 2.0)            # centred on its 2x2 doorway
			node = door
		"switch":
			var sw := FloorSwitch.new()
			var sflag := String(o["flag"])
			sw.setup(sflag, bool(o.get("heavy", false)), GameState.has_flag(sflag))
			sw.pressed_down.connect(_on_switch)
			node = sw
		"push_block":
			node = PushBlock.new()
		"heavy_rock":
			node = HeavyRock.new()
		"rubble":
			if GameState.has_flag(flag):
				return
			var rubble := Rubble.new()
			rubble.flag = flag
			rubble.broken.connect(func(_r: Node2D) -> void: GameState.set_flag(flag))
			node = rubble
		"hook_post":
			node = HookPost.new()
		"rift":
			if not GameState.has_flag(ACT1_FLAG):
				return                                    # rifts open only once Caver has torn the valley
			var rift := Rift.new()
			rift.setup(false)
			rift.entered.connect(func(_r: Node2D) -> void: _world_warp("overworld_dark", false))
			node = rift
		"seal_gate":
			var gate := SealGate.new()
			gate.setup(GATE_FLAG, GameState.has_flag(GATE_FLAG))
			at += Vector2(TILE / 2.0, TILE / 2.0)            # centred on its 2x2 gateway
			node = gate
			gate.ready.connect(func() -> void: gate.refresh(GameState.seal_count()))
		"torch":
			var torch := Torch.new()
			torch.lit_up.connect(_on_torch_lit)
			node = torch
		"cracked_rock":
			if GameState.has_flag(flag):
				return
			var rock := CrackedRock.new()
			rock.flag = flag
			rock.broken.connect(func(_r: Node2D) -> void: GameState.set_flag(flag))
			node = rock
		"key_block":
			if GameState.has_flag(flag):
				return
			var block := KeyBlock.new()
			block.flag = flag
			node = block
		"heart_piece":
			if GameState.has_flag(flag):
				return
			var piece: Area2D = PICKUP_SCRIPT.new()
			piece.kind = "heart_piece"
			piece.collected.connect(func(_k: String) -> void: GameState.set_flag(flag))
			node = piece
	if node != null:
		node.position = at
		actors.add_child(node)


static func object_flag(kind: String, area_id: String, cell: Array) -> String:
	return "%s:%s:%d,%d" % [kind, area_id, int(cell[0]), int(cell[1])]


func _free(rec: Dictionary) -> void:
	if rec.is_empty():
		return
	rec["tiles"].queue_free()
	rec["actors"].queue_free()


func _enter(area_id: String, feet: Vector2, facing: Vector2i = Vector2i.DOWN) -> void:
	if not current.is_empty():
		_last_area = current_id()
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
	darkness.global_position = player.global_position + PlayerTuning.BODY_CENTER


# Dark rooms ("dark": true) are black but for a little light around Joe - a wider one with the lantern - until
# every torch of the room burns.
func update_darkness() -> void:
	var dark := not current.is_empty() and bool(current["data"].get("dark", false)) and not _all_torches_lit()
	darkness.visible = dark
	darkness.texture = DARK_LANTERN if GameState.has_item("lantern") else DARK_SMALL


func _all_torches_lit() -> bool:
	var torches: Array = current["actors"].get_children().filter(func(n: Node) -> bool: return n is Torch)
	return not torches.is_empty() and torches.all(func(t: Node) -> bool: return t.lit)


# --- edges and doors ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_run_clock(delta)
	if transitioning or current.is_empty() or player.is_dead() or player.is_hopping():
		return
	var feet := player.global_position
	var data: Dictionary = current["data"]
	var group := group_of(current_id())
	if group != "" and not current["rect"].has_point(feet):
		var next := area_at(feet, group)
		if next != "":
			_scroll_to(next)
		return
	_check_room_cleared()
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


# Tempus's broken clock: while the area has tick blocks, every TICK_TIME s the raised colour swaps. It stops
# whenever the tree is paused (boxes, menus) and during scrolls.
func _run_clock(delta: float) -> void:
	if transitioning or current.is_empty() or current.get("tick_blocks", []).is_empty():
		return
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left = TICK_TIME
	tick_phase = 1 - tick_phase
	ticks += 1
	Audio.sfx("tick")
	_apply_ticks(current)


func _apply_ticks(rec: Dictionary) -> void:
	for b in rec.get("tick_blocks", []):
		if is_instance_valid(b):
			b.set_raised(b.amber == (tick_phase == 0))


# ALttP screen scroll: freeze everything, build the neighbour, slide the camera while Joe steps in.
func _scroll_to(next_id: String) -> void:
	transitioning = true
	var old := current
	old["actors"].process_mode = Node.PROCESS_MODE_DISABLED
	var dir := _edge_direction(old["rect"], player.global_position)
	var push := DUNGEON_PUSH if areas[next_id]["kind"] == "dungeon" else SCROLL_PUSH
	var to_feet := player.global_position + dir * push
	_last_area = old["id"]
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
	if target is Chest:
		_open_chest(target)
		return
	if target is Door:
		_open_door(target)
		return
	if target is SealGate:
		_try_seal_gate(target)
		return
	if target is KeyBlock:
		_use_key(target)
		return
	if target is ShopItem:
		_offer_ware(target)
		return
	var key := String(target.call("talk", player.global_position))
	var conv := DialogueData.conversation(key, GameState)
	var pages: Array = conv["pages"]
	if pages.is_empty():
		return
	if String(conv["gift"]) != "":
		var gift := String(conv["gift"])
		var amount := int(conv["amount"])
		_after_dialogue = func() -> void: item_get(gift, amount)
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
	if _after_dialogue.is_valid():
		var next := _after_dialogue
		_after_dialogue = Callable()
		next.call()


# Show a text box for a dialogue key (no speaker change, no gift handling).
func say(key: String) -> void:
	var on_screen := player.global_position - (camera.global_position - VIEW / 2.0)
	dialogue.open(DialogueData.pages_for(key, GameState), DialogueData.speaker(key), box_at_top(on_screen))


# --- items, chests, keys, shop ------------------------------------------------------------------------

# ALttP's item-get: grant it, Joe holds it up over his head, fanfare, its text; he lowers it when the box closes.
func item_get(kind: String, amount: int = 1) -> void:
	item_gets += 1
	var new_heart := grant(kind, amount)
	player.hold_up(ItemDB.icon(kind))
	Audio.sfx("heart_piece" if kind == "heart_piece" and not new_heart else "item_get")
	var text := ItemDB.text_key(kind)
	if kind == "seal":                                  # each seal has its own words
		var idx := int(dungeons.get(dungeon_of(current_id()), {}).get("seal", 0))
		if idx > 0 and DialogueData.has("get_seal_%d" % idx):
			text = "get_seal_%d" % idx
	if kind == "crystal":                               # ...and so does each dimension crystal
		var cidx := int(dungeons.get(dungeon_of(current_id()), {}).get("crystal", 0))
		if DialogueData.has("get_crystal_%d" % cidx):
			text = "get_crystal_%d" % cidx
	var pages: Array = DialogueData.pages_for(text, GameState)
	if new_heart and kind == "heart_piece":
		pages.append_array(DialogueData.pages_for(ItemDB.text_key("heart_container"), GameState))
	_after_dialogue = func() -> void: player.end_hold()
	if kind == "seal" or kind == "crystal":
		_after_dialogue = func() -> void:
			player.end_hold()
			leave_dungeon()
	var on_screen := player.global_position - (camera.global_position - VIEW / 2.0)
	dialogue.open(pages, "", box_at_top(on_screen))


# Apply `kind` to Joe / GameState. Returns true if Joe gained a heart container.
func grant(kind: String, amount: int = 1) -> bool:
	match kind:
		"lantern", "boomerang":
			GameState.give_item(kind)
		"bow":
			GameState.give_item(kind)
			GameState.add_ammo("arrows", BOW_ARROWS)
		"bombs":
			GameState.give_item(kind)
			GameState.add_ammo("bombs", amount)
		"arrows":
			GameState.add_ammo("arrows", amount)
		"small_key":
			GameState.add_keys(amount)
		"gems":
			GameState.add_gems(amount)
		"heart_piece":
			if GameState.add_heart_piece():
				_add_container()
				return true
		"heart_container":
			_add_container()
			return true
		"map", "compass", "big_key":
			GameState.give_dungeon_item(dungeon_of(current_id()), kind)
		"glove", "boots", "fire_rod", "moon_mirror", "grapple", "ice_rod", "hammer":
			GameState.give_item(kind)
		"magic":
			GameState.add_magic(amount)
		"seal":
			var info: Dictionary = dungeons.get(dungeon_of(current_id()), {})
			GameState.seals[int(info.get("seal", 0))] = true
		"crystal":
			var info: Dictionary = dungeons.get(dungeon_of(current_id()), {})
			GameState.crystals[int(info.get("crystal", 0))] = true
	return false


func _add_container() -> void:
	_set_hearts(player.health.max_health + CONTAINER_HP, player.health.max_health + CONTAINER_HP)


# Chests open from below (Joe facing up), once; a big chest also needs this dungeon's big key.
func _open_chest(chest: Chest) -> void:
	if not chest.can_open() or player.facing != Vector2i.UP:
		return
	if chest.needs_big_key and not GameState.has_dungeon_item(dungeon_of(current_id()), "big_key"):
		Audio.sfx("error")
		say("big_chest_locked")
		return
	chest.open()
	GameState.set_flag(chest.flag)
	Audio.sfx("chest_open")
	item_get(chest.kind, chest.amount)


func _use_key(block: KeyBlock) -> void:
	if GameState.keys <= 0:
		say(block.talk(player.global_position))
		return
	GameState.add_keys(-1)
	GameState.set_flag(block.flag)
	block.unlock()


# A locked door takes a small key of this dungeon; a big door needs the big key (kept, as in ALttP).
func _open_door(door: Door) -> void:
	if door.is_open:
		return
	if door.type == "locked":
		if GameState.keys <= 0:
			say("locked_door")
			return
		GameState.add_keys(-1)
	elif door.type == "big":
		if not GameState.has_dungeon_item(dungeon_of(current_id()), "big_key"):
			say("big_door")
			return
	else:
		return
	GameState.set_flag(door.flag())
	door.open_door()


func _offer_ware(item: ShopItem) -> void:
	_offer = item
	var on_screen := player.global_position - (camera.global_position - VIEW / 2.0)
	var key := item.talk(player.global_position)
	dialogue.open(DialogueData.pages_for(key, GameState), DialogueData.speaker(key), box_at_top(on_screen), SHOP_CHOICES)


func _on_answered(index: int) -> void:
	var item := _offer
	_offer = null
	if index == 0 and is_instance_valid(item):
		buy(item)


# Pay for a ware (if Joe can afford it and has room) and hand it over.
func buy(item: ShopItem) -> bool:
	var w: Dictionary = ItemDB.WARES[item.ware]
	var kind := String(w["kind"])
	var amount := int(w["amount"])
	if GameState.gems < item.price():
		Audio.sfx("error")
		say(shop_line(item, "shop_no_gems"))
		return false
	var is_ammo := kind == "arrows" or (kind == "bombs" and GameState.has_item("bombs")) or kind == "magic"
	var full := GameState.magic >= GameState.MAX_MAGIC if kind == "magic" else GameState.ammo_full(kind)
	if is_ammo and full:
		Audio.sfx("error")
		say(shop_line(item, "shop_full"))
		return false
	GameState.add_gems(-item.price())
	Audio.sfx("shop_buy")
	if bool(w["once"]):
		GameState.set_flag("ware:" + item.ware)
		item.sold_out()
	if is_ammo:
		grant(kind, amount)
		say(shop_line(item, "shop_thanks"))
	else:
		item_get(kind, amount)
	return true


# The shopkeeper's words for `key`: the Shade Market's wares ("dw_...") have their own merchant's lines.
func shop_line(item: ShopItem, key: String) -> String:
	if item.ware.begins_with("dw_") and DialogueData.has("dw_" + key):
		return "dw_" + key
	return key


# A torch caught fire: when every torch of the area burns, hidden chests appear.
func _on_torch_lit() -> void:
	var torches: Array = current["actors"].get_children().filter(func(n: Node) -> bool: return n is Torch)
	if torches.any(func(t: Node) -> bool: return not t.lit):
		return
	_reveal_chests(func(c: Chest) -> bool: return c.reveal_by == "torches")
	update_darkness()


func _reveal_chests(which: Callable) -> void:
	for n in current["actors"].get_children():
		if n is Chest and n.concealed and which.call(n):
			n.reveal()
			Juice.play_fx("poof", n.global_position, current["actors"])
			Audio.sfx("unlock")


# --- dungeons ------------------------------------------------------------------------------------------

func _on_area_entered(aid: String) -> void:
	GameState.visited[aid] = true
	update_darkness()
	var dungeon := dungeon_of(aid)
	hud.show_zero_keys = dungeon != ""
	GameState.set_key_pool(dungeon)
	# Moving from room to room of the same dungeon keeps quiet; entering it (or any other area) shows the name.
	if dungeon == "" or _last_area == "" or dungeon_of(_last_area) != dungeon:
		hud.show_caption(String(areas[aid]["name"]).to_upper())
	# The boss door shuts behind Joe until the boss falls.
	var boss_flag := String(areas[aid].get("boss_flag", ""))
	if boss_flag != "" and not GameState.has_flag(boss_flag):
		for n in current["actors"].get_children():
			if n is Door and n.type == "boss":
				n.close_door()


# Rooms with a clear flag remember being emptied of enemies (their shutters open, now and later).
func _check_room_cleared() -> void:
	var flag := String(current["data"].get("clear_flag", ""))
	if flag == "" or GameState.has_flag(flag):
		return
	for e in current["enemies"]:
		if is_instance_valid(e) and not e.is_dead():
			return
	GameState.set_flag(flag)
	_open_doors_when(flag)


func _open_doors_when(flag: String) -> void:
	for n in current["actors"].get_children():
		if n is Door and n.when == flag:
			n.open_door()


func _on_switch(flag: String) -> void:
	GameState.set_flag(flag)
	_open_doors_when(flag)
	_reveal_chests(func(c: Chest) -> bool: return c.reveal_by == "switch" and c.reveal_flag == flag)


func _on_fell() -> void:
	falls += 1
	Audio.sfx("hurt")
	player.health.take_damage(PlayerTuning.FALL_DAMAGE)
	if player.health.is_alive():
		player.respawn_after_fall(entry_point, entry_facing)
		_snap_camera()


func _on_boss_defeated(room: String) -> void:
	var flag := String(areas[room].get("boss_flag", ""))
	GameState.set_flag(flag)
	Audio.sfx("boss_die")
	Juice.shake(4.0, 0.6)
	for e in current["actors"].get_children():
		if e is BaseEnemy and not e.is_dead() and not e.get("is_boss"):
			Juice.play_fx("poof", e.global_position, current["actors"])
			e.queue_free()                                    # the boss's brood dies with it
	_open_doors_when(flag)
	var info: Dictionary = dungeons.get(dungeon_of(room), {})
	if String(info.get("ending", "")) != "":
		await get_tree().create_timer(ENDING_DELAY).timeout
		play_ending(String(info["ending"]))
		return
	await get_tree().create_timer(BOSS_REWARD_DELAY).timeout
	if current_id() == room:
		_spawn_boss_reward(current)


# After the boss: first a heart container, then the family seal or the dimension crystal (each only until taken).
func _spawn_boss_reward(rec: Dictionary) -> void:
	var room := String(rec["id"])
	var container_flag := "heart_container:" + room
	var at: Vector2 = rec["rect"].get_center() + REWARD_DROP
	var info: Dictionary = dungeons.get(dungeon_of(room), {})
	if int(info.get("seal", 0)) < 0:
		return                                            # the keep has no reward: its end is the act's end
	if not GameState.has_flag(container_flag):
		var c: Area2D = PICKUP_SCRIPT.new()
		c.kind = "heart_container"
		c.position = at
		c.collected.connect(func(_k: String) -> void:
			GameState.set_flag(container_flag)
			_spawn_boss_reward.call_deferred(rec))
		rec["actors"].add_child.call_deferred(c)
	elif info.has("crystal"):
		if not GameState.crystals[int(info["crystal"])]:
			var crystal: Area2D = PICKUP_SCRIPT.new()
			crystal.kind = "crystal"
			crystal.position = at - REWARD_DROP + SEAL_DROP
			rec["actors"].add_child.call_deferred(crystal)
	elif not GameState.seals[int(info.get("seal", 0))]:
		var seal: Area2D = PICKUP_SCRIPT.new()
		seal.kind = "seal"
		seal.position = at - REWARD_DROP + SEAL_DROP
		rec["actors"].add_child.call_deferred(seal)


# The keep's gate: it opens for good once all three family seals are home.
func _try_seal_gate(gate: SealGate) -> void:
	gate.refresh(GameState.seal_count())
	if GameState.seal_count() < GameState.SEAL_COUNT:
		say("seal_gate")
		return
	GameState.set_flag(GATE_FLAG)
	gate.open_gate()
	say("seal_gate_open")


# The end of an act: the villain's last words, then the end card; then save (outside the dungeon) and go back to
# the title. Act 1 ends when Caver's shade falls.
func play_ending(act: String) -> void:
	endings += 1
	GameState.set_flag(ACT1_FLAG if act == "act1" else act + ":done")
	_after_dialogue = func() -> void:
		var card: Array = DialogueData.pages_for("act1_card", GameState)
		end_card.open(DialogueData.speaker("act1_card"), card)
	var on_screen := player.global_position - (camera.global_position - VIEW / 2.0)
	dialogue.open(DialogueData.pages_for("caver_banish", GameState), DialogueData.speaker("caver_banish"),
			box_at_top(on_screen))


# After the end card: Caver's spell has thrown Joe into the Dark World. He is saved where he lands (Act 2 opens
# there on the next Continue), then the title.
func _on_end_card_finished() -> void:
	if not act2_spawn.is_empty() and areas.has(String(act2_spawn["area"])):
		var aid := String(act2_spawn["area"])
		_enter(aid, cell_feet(aid, act2_spawn["cell"]), Vector2i.DOWN)
	save_game()
	quit_to_title()


# --- the two worlds -------------------------------------------------------------------------------------

# The Moon Mirror: only in the Dark World; Joe steps into the Light World at the same spot.
func _on_mirror() -> void:
	if transitioning:
		return
	if not is_dark(current_id()):
		say("mirror_light")
		return
	if area_at(player.global_position, "overworld") == "":
		say("mirror_void")                              # Dark World-only lands (the dimensions) have no twin
		return
	_world_warp("overworld", true)


# Move Joe to the area of `group` under his feet (same coordinates). `mirror`: bounce back if he would land in
# something solid, otherwise leave a shimmer there that takes him back.
func _world_warp(group: String, mirror: bool) -> void:
	var feet := player.global_position
	var target := area_at(feet, group)
	if target == "" or transitioning:
		return
	transitioning = true
	var from := current_id()
	var facing := player.facing
	player.freeze(WORLD_FADE * 6.0)
	Audio.sfx("warp")
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, WORLD_FADE)
	await tw.finished
	_enter(target, feet, facing)
	if mirror:
		if _solid_at(feet):
			mirror_bounces += 1
			_enter(from, feet, facing)
			say.call_deferred("mirror_blocked")
		else:
			var portal := Rift.new()
			portal.setup(true)
			portal.position = feet
			portal.entered.connect(func(_r: Node2D) -> void: _world_warp("overworld_dark", false))
			current["actors"].add_child(portal)
	world_warps += 1
	var tw2 := create_tween()
	tw2.tween_property(_fade, "modulate:a", 0.0, WORLD_FADE)
	await tw2.finished
	player.unfreeze()
	transitioning = false


# True if the current area's tile under `feet` is solid (a mirror warp may not land there).
func _solid_at(feet: Vector2) -> bool:
	var tiles: TileMapLayer = current["tiles"]
	var td := tiles.get_cell_tile_data(tiles.local_to_map(tiles.to_local(feet + SOLID_PROBE)))
	return td != null and td.get_collision_polygons_count(0) > 0


# Back out to the overworld in front of the dungeon's entrance (after the seal).
func leave_dungeon() -> void:
	var info: Dictionary = dungeons.get(dungeon_of(current_id()), {})
	var entrance: Dictionary = areas.get(String(info.get("entrance", "")), {})
	if entrance.is_empty() or entrance["exits"].is_empty():
		return
	var e: Dictionary = entrance["exits"][0]
	_warp(String(e["to"]), cell_feet(String(e["to"]), e["spawn_cell"]), FACINGS[String(e["facing"])])


# --- menus ------------------------------------------------------------------------------------------

# True when nothing else owns the screen (no scroll, fade, conversation, menu or death in progress).
func can_open_menu() -> bool:
	return not transitioning and not dialogue.is_open and not pause_menu.is_open and not item_menu.is_open \
			and not game_over.is_open and not map_screen.is_open and not end_card.is_open and not player.is_dead() \
			and not player.is_falling()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not can_open_menu():
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		pause_menu.open()
	elif event.is_action_pressed("inventory"):
		get_viewport().set_input_as_handled()
		item_menu.open()
	elif event.is_action_pressed("map"):
		get_viewport().set_input_as_handled()
		map_screen.open(areas, current_id(), dungeons)


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
