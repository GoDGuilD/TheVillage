extends CanvasLayer
## Manages transitions between rooms and scenes with fade.
## Usage: SceneManager.go_to_room("res://scenes/world/rooms/Room1_Tutorial.tscn", "south")
##
## Flow of a complete transition:
##   1. Fade to black
##   2. Save the player's health in GameManager (before destroying the scene)
##   3. Change scene (the previous scene is freed, the new one is initialized)
##   4. Wait one frame (all _ready() calls of the new scene run)
##   5. Emit room_entered → the room moves the player to the spawn (still black)
##   6. Fade from black to visible
##
## Step 5 happens with a black screen to avoid the visual "pop" of teleporting.

signal transition_started()
signal transition_finished()

var _is_transitioning: bool = false
var _fade: ColorRect

func _ready() -> void:
	## Layer 128: above everything, including the Game Over screen (layer 127).
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
	## Save health BEFORE freeing the current scene (the Player node will be destroyed soon)
	GameManager.save_player_health()
	get_tree().change_scene_to_file(scene_path)
	## Wait one frame so all _ready() calls of the new scene complete
	await get_tree().process_frame
	## Position the player at the spawn while the screen is still black — no visual pop
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
