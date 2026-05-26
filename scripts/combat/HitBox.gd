extends Area2D
class_name HitBox
## Marca un área que INFLIGE daño. No detecta nada por sí sola.
## El HurtBox del objetivo la detecta y lee su propiedad 'damage'.
##
## Capas de colisión:
##   - Espada jugador: Layer 4 (valor 8)
##   - Contacto enemigo: Layer 5 (valor 16)

@export var damage: int = 1
