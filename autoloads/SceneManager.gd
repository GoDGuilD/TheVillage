extends CanvasLayer
## Gestiona transiciones entre salas y escenas con fade.
## Uso: SceneManager.go_to_room("res://scenes/world/rooms/Sala1.tscn", "sur")
##
## Flujo de una transición completa:
##   1. Fade a negro
##   2. Guardar vida del jugador en GameManager (antes de destruir la escena)
##   3. Cambiar escena (la escena anterior se libera, la nueva se inicializa)
##   4. Esperar un frame (todos los _ready() de la nueva escena se ejecutan)
##   5. Emitir room_entered → la sala mueve al jugador al spawn (aún en negro)
##   6. Fade desde negro hasta visible
##
## El paso 5 ocurre con pantalla negra para evitar el "pop" visual del teletransporte.

signal transition_started()
signal transition_finished()

var _is_transitioning: bool = false
var _fade: ColorRect

func _ready() -> void:
	## Capa 128: por encima de todo, incluida la pantalla de Game Over (capa 127).
	layer = 128
	_fade = ColorRect.new()
	_fade.name = "FadeRect"
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)

func go_to_room(scene_path: String, spawn_id: String = "") -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	transition_started.emit()
	await _fade_out()
	## Guardar vida ANTES de liberar la escena actual (el nodo Player se destruirá enseguida)
	GameManager.save_player_health()
	get_tree().change_scene_to_file(scene_path)
	## Esperar un frame para que todos los _ready() de la nueva escena se completen
	await get_tree().process_frame
	## Posicionar al jugador en el spawn con pantalla aún negra — sin pop visual
	if spawn_id:
		EventBus.room_entered.emit(spawn_id)
	await _fade_in()
	_is_transitioning = false
	transition_finished.emit()

func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, Constants.FADE_DURATION)
	await tween.finished

func _fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 0.0, Constants.FADE_DURATION)
	await tween.finished
