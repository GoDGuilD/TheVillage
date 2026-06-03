extends Area2D
class_name HeartPickup
## Objeto recogible: medio corazón. Cura 1 punto de vida al jugador al tocarlo.
## Spawneado por Slime._on_died() con probabilidad Constants.HEART_DROP_CHANCE.
##
## Arquitectura:
##   - Area2D con collision_mask=2 (capa Player) para detectar al jugador por body_entered.
##   - collision_layer=0: el pickup no necesita ser detectado por nadie más.
##   - PlaceholderSprite rojo 8×8 hasta la fase de sprites reales.

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	PlaceholderSprite.inject(_sprite, Color(0.9, 0.15, 0.15), Vector2i(8, 8))

func _on_body_entered(body: Node) -> void:
	if not body is Player:
		return
	var health := body.get_node_or_null("HealthComponent") as HealthComponent
	if health:
		health.heal(1)
	queue_free()
