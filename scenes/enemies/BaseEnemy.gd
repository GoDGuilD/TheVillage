extends CharacterBody2D
class_name BaseEnemy
## Base class for all enemies. Defines the state machine and shared behaviors.
## Subclasses only override _update_idle() and _update_chase().

enum State { IDLE, CHASE, DEAD }

@export var move_speed: float = 30.0
@export var detection_radius: float = 80.0

var _state: State = State.IDLE

@onready var _health: HealthComponent = $HealthComponent
@onready var _hurt_box: HurtBox = $HurtBox
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	GameManager.register_enemy(self)
	_hurt_box.hurt.connect(_on_hurt)
	_health.died.connect(_on_died)

func _physics_process(_delta: float) -> void:
	match _state:
		State.IDLE:  _update_idle()
		State.CHASE: _update_chase()

## Override in the subclass
func _update_idle() -> void:
	pass

## Override in the subclass
func _update_chase() -> void:
	pass

func _get_player() -> CharacterBody2D:
	return GameManager.get_player()

func _distance_to_player() -> float:
	var p := _get_player()
	if not p:
		return INF
	return global_position.distance_to(p.global_position)

func _on_hurt(damage: int, _source_position: Vector2) -> void:
	_health.take_damage(damage)

func _on_died() -> void:
	_state = State.DEAD
	set_physics_process(false)
	GameManager.unregister_enemy(self)
	EventBus.enemy_died.emit(self)
	_play_death_tween()

func _play_death_tween() -> void:
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
