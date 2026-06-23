extends Camera2D
class_name PixelCamera
## Camera that follows the player with snapping to integer pixels.
## Eliminates the shimmer (sub-pixel jitter) typical of pixel art in motion.
## Combined with stretch_mode=canvas_items + scale_mode=integer in project.godot.

func _physics_process(_delta: float) -> void:
	## Rounds after the engine's follow to guarantee integer pixels.
	## Uses _physics_process because the player moves in physics_process.
	global_position = global_position.round()
