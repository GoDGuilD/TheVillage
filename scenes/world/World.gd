extends Node2D

@onready var _health_ui: CanvasLayer = $HealthUI
@onready var _tilemap: TileMapLayer = $TileMapLayer

func _ready() -> void:
	_generate_floor()
	call_deferred("_setup_ui")

func _generate_floor() -> void:
	# Skip if the TileMapLayer already has a tileset configured in the editor
	if _tilemap.tile_set:
		return

	# Floor tile: solid green with 1px darker border
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
	ts.tile_size = Vector2i(16, 16)

	var src := TileSetAtlasSource.new()
	src.texture = ImageTexture.create_from_image(img)
	src.texture_region_size = Vector2i(16, 16)
	src.create_tile(Vector2i.ZERO)

	var src_id := ts.add_source(src)
	_tilemap.tile_set = ts

	# 24×16 tiles = 384×256 px, centered on origin — covers 320×180 viewport with margin
	for x in range(-12, 12):
		for y in range(-8, 8):
			_tilemap.set_cell(Vector2i(x, y), src_id, Vector2i.ZERO)

func _setup_ui() -> void:
	var player := GameManager.get_player()
	if not player:
		return
	var health := player.get_node("HealthComponent") as HealthComponent
	if health:
		_health_ui.setup(health.max_health)
