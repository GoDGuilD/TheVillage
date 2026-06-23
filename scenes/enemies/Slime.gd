extends BaseEnemy
## Slime: basic enemy. Patrols randomly while idle, chases the player in chase state.
## Contact damage: its always-active HitBox deals damage when it touches the player.
## Has a 30% chance to drop a HeartPickup on death.

const IDLE_MOVE_INTERVAL_MIN := 1.5
const IDLE_MOVE_INTERVAL_MAX := 3.0

const HEART_PICKUP_SCENE := preload("res://scenes/items/HeartPickup.tscn")

var _idle_direction: Vector2 = Vector2.ZERO
var _idle_timer: float = 0.0

func _ready() -> void:
	super._ready()
	PlaceholderSprite.inject(_sprite, Color(0.2, 0.78, 0.2), Vector2i(10, 10))
	_new_idle_direction()

func _update_idle() -> void:
	if _distance_to_player() <= detection_radius:
		_state = State.CHASE
		return

	_idle_timer -= get_physics_process_delta_time()
	if _idle_timer <= 0.0:
		_new_idle_direction()

	velocity = _idle_direction * move_speed * 0.4
	move_and_slide()
	_update_anim()

func _update_chase() -> void:
	var player := _get_player()
	if not player or _distance_to_player() > detection_radius * 1.5:
		_state = State.IDLE
		return

	var dir := (player.global_position - global_position).normalized()
	velocity = dir * move_speed
	move_and_slide()
	_update_anim()

func _new_idle_direction() -> void:
	_idle_timer = randf_range(IDLE_MOVE_INTERVAL_MIN, IDLE_MOVE_INTERVAL_MAX)
	# 40% chance of staying still
	if randf() < 0.4:
		_idle_direction = Vector2.ZERO
	else:
		var angle := randf() * TAU
		_idle_direction = Vector2(cos(angle), sin(angle))

func _on_died() -> void:
	## Spawn the pickup BEFORE the death animation so it appears at the correct position.
	if randf() < Constants.HEART_DROP_CHANCE:
		var pickup := HEART_PICKUP_SCENE.instantiate()
		pickup.global_position = global_position
		get_parent().add_child(pickup)
	super._on_died()

func _update_anim() -> void:
	if not _sprite.sprite_frames:
		return
	var anim := "walk" if velocity.length_squared() > 4.0 else "idle"
	if _sprite.sprite_frames.has_animation(anim) and _sprite.animation != anim:
		_sprite.play(anim)
