extends Node2D

@onready var _health_ui: CanvasLayer = $HealthUI
@onready var _tilemap: TileMapLayer = $TileMapLayer

func _ready() -> void:
	_generate_floor()
	_generate_walls()
	call_deferred("_setup_ui")

func _generate_floor() -> void:
	if _tilemap.tile_set:
		return

	var img := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.26, 0.52, 0.22))
	var border_col := Color(0.14, 0.30, 0.12)
	for x in 16:
		img.set_pixel(x, 0, border_col)
		img.set_pixel(x, 15, border_col)
	for y in 16:
		img.set_pixel(0, y, border_col)
		img.set_pixel(15, y, border_col)

	var ts := TileSet.new()
	ts.tile_size = Vector2i(Constants.TILE_SIZE, Constants.TILE_SIZE)

	var src := TileSetAtlasSource.new()
	src.texture = ImageTexture.create_from_image(img)
	src.texture_region_size = Vector2i(Constants.TILE_SIZE, Constants.TILE_SIZE)
	src.create_tile(Vector2i.ZERO)

	var src_id := ts.add_source(src)
	_tilemap.tile_set = ts

	for x in range(-Constants.WORLD_HALF_TILES_X, Constants.WORLD_HALF_TILES_X):
		for y in range(-Constants.WORLD_HALF_TILES_Y, Constants.WORLD_HALF_TILES_Y):
			_tilemap.set_cell(Vector2i(x, y), src_id, Vector2i.ZERO)

func _generate_walls() -> void:
	var hw := Constants.WORLD_HALF_TILES_X * Constants.TILE_SIZE  # 192 px
	var hh := Constants.WORLD_HALF_TILES_Y * Constants.TILE_SIZE  # 128 px
	var t  := 8.0  # half-thickness of each wall segment

	var body := StaticBody2D.new()
	body.name = "WorldBounds"
	add_child(body)

	# [center_x, center_y, half_width, half_height]
	var segments: Array = [
		[0.0,      -(hh + t), hw + t, t],  # top
		[0.0,       (hh + t), hw + t, t],  # bottom
		[-(hw + t), 0.0,      t, hh + t],  # left
		[ (hw + t), 0.0,      t, hh + t],  # right
	]
	for s in segments:
		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(s[2] * 2.0, s[3] * 2.0)
		cs.shape = rect
		cs.position = Vector2(s[0], s[1])
		body.add_child(cs)

func _setup_ui() -> void:
	var player := GameManager.get_player()
	if not player:
		return
	var health := player.get_node("HealthComponent") as HealthComponent
	if health:
		_health_ui.setup(health.max_health)
