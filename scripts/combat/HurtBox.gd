extends Area2D
class_name HurtBox
## Marks an area that RECEIVES damage. Monitors collisions with HitBox.
##
## The 'hurt' signal passes both the damage and the HitBox's global position.
## This allows computing knockback direction without coupling to the attacker.

signal hurt(damage: int, source_position: Vector2)

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if not area is HitBox:
		return
	hurt.emit((area as HitBox).damage, area.global_position)
