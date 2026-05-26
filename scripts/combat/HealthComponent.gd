extends Node
class_name HealthComponent
## Componente reutilizable de vida. Se agrega como nodo hijo a cualquier entidad.
## Emite señales en lugar de modificar el nodo padre directamente (bajo acoplamiento).

signal health_changed(current: int, maximum: int)
signal died()

@export var max_health: int = 3

var current_health: int

func _ready() -> void:
	current_health = max_health

func take_damage(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = maxi(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		died.emit()

func heal(amount: int) -> void:
	current_health = mini(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func is_alive() -> bool:
	return current_health > 0
