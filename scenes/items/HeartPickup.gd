extends Area2D
class_name HeartPickup
## Collectible item: half heart. Heals 1 health point on the player when touched.
## Spawned by Slime._on_died() with probability Constants.HEART_DROP_CHANCE.
##
## Architecture:
##   - Area2D with collision_mask=2 (Player layer) to detect the player via body_entered.
##   - collision_layer=0: the pickup doesn't need to be detected by anyone else.
##   - Red 8×8 PlaceholderSprite until the real-sprites phase.

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
