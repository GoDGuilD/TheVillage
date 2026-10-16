# File: MapScreen.gd
# Description: The map (Tab / North button) - in a dungeon its rooms (visited ones, or all with the dungeon map), Joe's room blinking and, with the compass, the boss room; outside, the overworld areas Joe has seen.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-16
# Last edit date: 2026-10-16
# Version: 1.0.0
class_name MapScreen
extends CanvasLayer
## Rooms and areas are drawn as boxes on their screen grid (one box per screen). The World passes its area data in;
## the map reads GameState for what Joe has seen and found. Pauses the world while open.

signal closed

const PANEL_POS := Vector2(32, 18)
const PANEL_SIZE := Vector2(320, 180)
const CELL := Vector2(40, 24)            # one screen on the map
const GAP := 3.0
const TITLE_Y := 9.0
const GRID_TOP := 26.0
const FOOTER_Y := 162.0
const ICON_STEP := 22.0
const BLINK_HZ := 3.0
const CLOSE_ACTIONS := ["map", "ui_cancel", "pause"]
const ICON_DIR := "res://assets/ui/items/"

var is_open := false
var shown_rooms: Array[String] = []      # area ids drawn this time (tests)
var here := ""                           # the room/area Joe is in
var boss_marked := ""                    # the boss room id, if the compass shows it

var _root: Control
var _content: Control
var _here_box: ColorRect
var _blink := 0.0


func _ready() -> void:
	layer = UiTheme.LAYER_MENU
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	add_child(_root)
	_root.add_child(UiTheme.overlay(UiTheme.DIM))
	_root.add_child(UiTheme.box(PANEL_POS, PANEL_SIZE))
	_content = Control.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_content)


# `areas` = World.areas, `current` = the area Joe is in, `dungeons` = the index's dungeon table.
func open(areas: Dictionary, current: String, dungeons: Dictionary) -> void:
	for c in _content.get_children():
		c.queue_free()
	shown_rooms.clear()
	boss_marked = ""
	here = current
	var data: Dictionary = areas[current]
	var dungeon := String(data.get("dungeon", ""))
	if dungeon != "":
		_draw_dungeon(areas, dungeon, dungeons.get(dungeon, {}))
	else:
		_draw_overworld(areas)
	is_open = true
	_root.visible = true
	get_tree().paused = true
	Audio.sfx("pause")


func close() -> void:
	if not is_open:
		return
	is_open = false
	_root.visible = false
	get_tree().paused = false
	Audio.sfx("menu_back")
	closed.emit()


func _draw_dungeon(areas: Dictionary, dungeon: String, info: Dictionary) -> void:
	_title(String(info.get("name", "DUNGEON")).to_upper())
	var has_map := GameState.has_dungeon_item(dungeon, "map")
	var has_compass := GameState.has_dungeon_item(dungeon, "compass")
	var rooms := []
	for aid in areas:
		if String(areas[aid].get("dungeon", "")) == dungeon:
			rooms.append(aid)
	var cells := {}
	for aid in rooms:
		var g: Array = areas[aid]["grid"]
		cells[aid] = Rect2(Vector2(float(g[0]), float(g[1])), Vector2.ONE)
	var origin := _grid_origin(cells)
	for aid in rooms:
		var seen := bool(GameState.visited.get(aid, false))
		if not seen and not has_map:
			continue
		_box(cells[aid], origin, UiTheme.MAP_ROOM if seen else UiTheme.MAP_KNOWN, aid)
	var boss_room := String(info.get("boss_room", ""))
	if has_compass and boss_room != "" and not GameState.has_flag(String(info.get("boss_flag", ""))):
		boss_marked = boss_room
		var r: Rect2 = cells[boss_room]
		var dot := ColorRect.new()
		dot.color = UiTheme.MAP_BOSS
		dot.size = Vector2(8, 8)
		dot.position = origin + (r.position * (CELL + Vector2.ONE * GAP)) + CELL / 2.0 - dot.size / 2.0
		_content.add_child(dot)
	# Footer: the dungeon items found here, and the small keys held.
	var x := PANEL_POS.x + 16.0
	for item in ItemDB.DUNGEON_ITEMS:
		if GameState.has_dungeon_item(dungeon, item):
			var s := Sprite2D.new()
			s.texture = load(ICON_DIR + item + ".png")
			s.centered = false
			s.position = Vector2(x, PANEL_POS.y + FOOTER_Y - 4)
			_content.add_child(s)
			x += ICON_STEP
	_content.add_child(PixelText.make("KEYS %d" % GameState.keys, PANEL_POS + Vector2(PANEL_SIZE.x - 16, FOOTER_Y),
			UiTheme.TEXT, PixelText.FONT_LARGE, PixelText.Align.RIGHT))


func _draw_overworld(areas: Dictionary) -> void:
	_title("THE VALLEY")
	var cells := {}
	for aid in areas:
		var a: Dictionary = areas[aid]
		if a["kind"] != "overworld":
			continue
		var o: Array = a["origin_tiles"]
		var sz: Array = a["size_screens"]
		cells[aid] = Rect2(Vector2(float(o[0]) / 24.0, float(o[1]) / 14.0), Vector2(float(sz[0]), float(sz[1])))
	var origin := _grid_origin(cells)
	var where := here
	if areas[here]["kind"] != "overworld":
		where = ""                          # inside a house: no marker
	for aid in cells:
		if not bool(GameState.visited.get(aid, false)):
			continue
		_box(cells[aid], origin, UiTheme.MAP_ROOM, aid if aid == where else "")
		if not shown_rooms.has(aid):
			shown_rooms.append(aid)
		var r: Rect2 = cells[aid]
		var centre := origin + r.position * (CELL + Vector2.ONE * GAP) + (r.size * (CELL + Vector2.ONE * GAP) - Vector2.ONE * GAP) / 2.0
		_content.add_child(PixelText.make(String(areas[aid]["name"]).to_upper(), centre - Vector2(0, 3), UiTheme.TEXT,
				PixelText.FONT_SMALL, PixelText.Align.CENTER))


func _title(text: String) -> void:
	_content.add_child(PixelText.make(text, PANEL_POS + Vector2(PANEL_SIZE.x / 2.0, TITLE_Y), UiTheme.GOLD,
			PixelText.FONT_LARGE, PixelText.Align.CENTER))


# Top-left of the grid so the whole set of cells is centred in the panel.
func _grid_origin(cells: Dictionary) -> Vector2:
	if cells.is_empty():
		return PANEL_POS
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for r in cells.values():
		lo = lo.min(r.position)
		hi = hi.max(r.end)
	var step := CELL + Vector2.ONE * GAP
	var size := (hi - lo) * step - Vector2.ONE * GAP
	var top_left := PANEL_POS + Vector2((PANEL_SIZE.x - size.x) / 2.0, GRID_TOP)
	return (top_left - lo * step).round()


func _box(cell: Rect2, origin: Vector2, color: Color, aid: String) -> void:
	var step := CELL + Vector2.ONE * GAP
	var edge := ColorRect.new()
	edge.color = UiTheme.MAP_EDGE
	edge.position = origin + cell.position * step - Vector2.ONE
	edge.size = cell.size * step - Vector2.ONE * GAP + Vector2.ONE * 2.0
	_content.add_child(edge)
	var fill := ColorRect.new()
	fill.color = color
	fill.position = edge.position + Vector2.ONE
	fill.size = edge.size - Vector2.ONE * 2.0
	_content.add_child(fill)
	if aid != "" and not shown_rooms.has(aid):
		shown_rooms.append(aid)
	if aid == here:
		_here_box = ColorRect.new()
		_here_box.color = UiTheme.MAP_HERE
		_here_box.size = Vector2(6, 6)
		_here_box.position = fill.position + fill.size / 2.0 - _here_box.size / 2.0
		_content.add_child(_here_box)


func _process(delta: float) -> void:
	if not is_open or not is_instance_valid(_here_box):
		return
	_blink += delta
	_here_box.visible = int(_blink * BLINK_HZ * 2.0) % 2 == 0


func _unhandled_input(event: InputEvent) -> void:
	if not is_open or event.is_echo():
		return
	for a in CLOSE_ACTIONS:
		if event.is_action_pressed(a):
			get_viewport().set_input_as_handled()
			close()
			return
