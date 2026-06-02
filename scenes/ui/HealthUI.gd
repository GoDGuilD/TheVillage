extends CanvasLayer
## HUD de vida. Muestra corazones como ColorRect (placeholders).
## Reemplazar los ColorRect por TextureRect cuando tengas sprites de corazones.
## También es responsable de instanciar la pantalla de Game Over al morir.

const HEART_SIZE := Vector2(14, 14)
const HEART_SPACING := 2
const COLOR_FULL  := Color(0.9, 0.15, 0.15)
const COLOR_EMPTY := Color(0.25, 0.25, 0.25, 0.6)

## Escena de Game Over — se carga una sola vez, se instancia cuando el jugador muere.
const GAME_OVER_SCENE := preload("res://scenes/ui/GameOver.tscn")

var _hearts: Array[ColorRect] = []

@onready var _container: HBoxContainer = $HBoxContainer

func _ready() -> void:
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.player_died.connect(_on_player_died)

## Llamar desde World después de que el jugador esté listo
func setup(max_health: int) -> void:
	for child in _container.get_children():
		child.queue_free()
	_hearts.clear()

	for i in max_health:
		var rect := ColorRect.new()
		rect.custom_minimum_size = HEART_SIZE
		rect.color = COLOR_FULL
		_container.add_child(rect)
		_hearts.append(rect)

func _on_health_changed(current: int, maximum: int) -> void:
	if _hearts.size() != maximum:
		setup(maximum)
	for i in _hearts.size():
		_hearts[i].color = COLOR_FULL if i < current else COLOR_EMPTY

func _on_player_died() -> void:
	## Instanciar la pantalla de Game Over y añadirla al root del árbol.
	## Se añade al root (no a World) para garantizar que persiste durante el fade
	## y que su layer esté por encima de todo lo que existe en la escena actual.
	var game_over := GAME_OVER_SCENE.instantiate()
	get_tree().root.add_child(game_over)
