extends Area2D
class_name HurtBox
## Marca un área que RECIBE daño. Monitorea colisiones con HitBox.
##
## La señal 'hurt' pasa tanto el daño como la posición global del HitBox.
## Esto permite calcular dirección de knockback sin acoplar al atacante.

signal hurt(damage: int, source_position: Vector2)

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if not area is HitBox:
		return
	hurt.emit((area as HitBox).damage, area.global_position)
