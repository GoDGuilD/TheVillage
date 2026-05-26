extends Camera2D
class_name PixelCamera
## Cámara que sigue al jugador con snapping a píxeles enteros.
## Elimina el shimmer (vibración sub-pixel) típico del pixel art en movimiento.
## Se combina con stretch_mode=canvas_items + scale_mode=integer en project.godot.

func _physics_process(_delta: float) -> void:
	## Redondea después del follow del engine para garantizar píxeles enteros.
	## Se usa _physics_process porque el jugador se mueve en physics_process.
	global_position = global_position.round()
