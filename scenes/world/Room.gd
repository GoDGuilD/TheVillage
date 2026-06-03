extends Node2D
## Script base para todas las salas del juego.
## Genera el suelo y las paredes, bloquea la cámara a una pantalla,
## y posiciona al jugador en el punto de spawn correcto al entrar.
##
## Convención de nodos en el .tscn de cada sala:
##   TileMapLayer        — recibe el suelo generado por código
##   PuntosSpawn/        — Node2D con hijos: SpawnNorte, SpawnSur, SpawnEste, SpawnOeste
##   Enemigos/           — instancias de enemigos de la sala
##   Puertas/            — instancias de Door.tscn
##   Player              — instancia de Player.tscn (posición inicial: centro de la sala)
##   HealthUI            — instancia de HealthUI.tscn

@onready var _tilemap:    TileMapLayer = $TileMapLayer
@onready var _health_ui:  CanvasLayer  = $HealthUI

func _ready() -> void:
	## Conectar antes de que SceneManager pueda emitir room_entered
	EventBus.room_entered.connect(_on_room_entered)
	_generate_floor()
	_generate_walls()
	_setup_camera_limits()
	## call_deferred garantiza que Player._ready() ya se ejecutó y está registrado en GameManager
	call_deferred("_setup_ui")

# ─── Generación de sala ───────────────────────────────────────────────────────

func _generate_floor() -> void:
	## Si el TileMap ya tiene un tileset asignado en el editor, respetarlo.
	if _tilemap.tile_set:
		return
	## Usar el tileset real. El tile de pasto ocupa la esquina superior-izquierda (atlas 0,0).
	var tex := load("res://assets/sprites/world/tileset_forest.png") as Texture2D
	var ts := TileSet.new()
	ts.tile_size = Vector2i(Constants.TILE_SIZE, Constants.TILE_SIZE)
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(Constants.TILE_SIZE, Constants.TILE_SIZE)
	src.create_tile(Vector2i.ZERO)
	var src_id := ts.add_source(src)
	_tilemap.tile_set = ts
	for x in range(-Constants.ROOM_HALF_TILES_X, Constants.ROOM_HALF_TILES_X):
		for y in range(-Constants.ROOM_HALF_TILES_Y, Constants.ROOM_HALF_TILES_Y):
			_tilemap.set_cell(Vector2i(x, y), src_id, Vector2i.ZERO)

func _generate_walls() -> void:
	## Cuatro muros invisibles alrededor de la sala usando un StaticBody2D único.
	var hw := Constants.ROOM_HALF_TILES_X * Constants.TILE_SIZE   # 160 px
	var hh := Constants.ROOM_HALF_TILES_Y * Constants.TILE_SIZE   # 96 px
	var t  := 8.0  # semiespesor de cada muro
	var body := StaticBody2D.new()
	body.name = "Paredes"
	add_child(body)
	## [center_x, center_y, semi_ancho, semi_alto]
	var segmentos: Array = [
		[0.0,      -(hh + t), hw + t, t],   # norte
		[0.0,       (hh + t), hw + t, t],   # sur
		[-(hw + t), 0.0,      t, hh + t],   # oeste
		[ (hw + t), 0.0,      t, hh + t],   # este
	]
	for s in segmentos:
		var cs   := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(s[2] * 2.0, s[3] * 2.0)
		cs.shape    = rect
		cs.position = Vector2(s[0], s[1])
		body.add_child(cs)

func _setup_camera_limits() -> void:
	## Bloquear la cámara exactamente al viewport para efecto de sala única (sin scroll).
	var camera := get_viewport().get_camera_2d()
	if not camera:
		return
	camera.limit_left   = -Constants.VIEWPORT_HALF_W
	camera.limit_right  =  Constants.VIEWPORT_HALF_W
	camera.limit_top    = -Constants.VIEWPORT_HALF_H
	camera.limit_bottom =  Constants.VIEWPORT_HALF_H

# ─── UI ───────────────────────────────────────────────────────────────────────

func _setup_ui() -> void:
	var player := GameManager.get_player()
	if not player:
		return
	var health := player.get_node_or_null("HealthComponent") as HealthComponent
	if not health:
		return
	_health_ui.setup(health.max_health)
	## Sincronizar la UI con la vida actual (importante si viene de otra sala con daño)
	EventBus.player_health_changed.emit(health.current_health, health.max_health)

# ─── Spawn ────────────────────────────────────────────────────────────────────

func _on_room_entered(spawn_id: String) -> void:
	## Buscar el nodo PuntosSpawn/SpawnXxx y mover al jugador allí.
	## spawn_id = "norte", "sur", "este", "oeste" → nodo = "SpawnNorte", "SpawnSur", etc.
	var puntos := get_node_or_null("PuntosSpawn")
	if not puntos:
		push_warning("Room: no existe el nodo 'PuntosSpawn'.")
		return
	var nombre := "Spawn" + spawn_id.capitalize()
	var punto  := puntos.get_node_or_null(nombre)
	if not punto:
		push_warning("Room: punto de spawn '%s' no encontrado en PuntosSpawn." % nombre)
		return
	var player := GameManager.get_player()
	if player:
		player.global_position = punto.global_position
