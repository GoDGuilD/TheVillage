extends Area2D
class_name HitBox
## Marks an area that DEALS damage. Detects nothing on its own.
## The target's HurtBox detects it and reads its 'damage' property.
##
## Collision layers:
##   - Player sword: Layer 4 (value 8)
##   - Enemy contact: Layer 5 (value 16)

@export var damage: int = 1
