extends CanvasLayer
## Health HUD. Shows hearts as ColorRect (placeholders).
## Replace the ColorRect with TextureRect once you have heart sprites.
## Also responsible for instantiating the Game Over screen on death.

const HEART_SIZE := Vector2(14, 14)
const HEART_SPACING := 2
const COLOR_FULL  := Color(0.9, 0.15, 0.15)
const COLOR_EMPTY := Color(0.25, 0.25, 0.25, 0.6)

## Game Over scene — loaded once, instantiated when the player dies.
const GAME_OVER_SCENE := preload("res://scenes/ui/GameOver.tscn")

var _hearts: Array[ColorRect] = []

@onready var _container: HBoxContainer = $HBoxContainer

func _ready() -> void:
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.player_died.connect(_on_player_died)

## Call from World after the player is ready
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
	## Instantiate the Game Over screen and add it to the tree root.
	## Added to root (not to World) to guarantee it persists during the fade
	## and that its layer is above everything in the current scene.
	var game_over := GAME_OVER_SCENE.instantiate()
	get_tree().root.add_child(game_over)
