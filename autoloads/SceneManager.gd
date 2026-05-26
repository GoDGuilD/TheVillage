extends Node
## Gestiona transiciones entre salas y escenas con fade.
## Uso: SceneManager.go_to_room("res://scenes/world/rooms/Room_Forest_01.tscn")

signal transition_started()
signal transition_finished()

var _is_transitioning: bool = false

@onready var _fade: ColorRect = $FadeRect

func _ready() -> void:
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE

func go_to_room(scene_path: String, spawn_id: String = "") -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	transition_started.emit()
	await _fade_out()
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await _fade_in()
	_is_transitioning = false
	transition_finished.emit()
	if spawn_id:
		EventBus.room_entered.emit(spawn_id)

func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.3)
	await tween.finished

func _fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 0.0, 0.3)
	await tween.finished
