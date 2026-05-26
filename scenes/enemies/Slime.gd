extends BaseEnemy
## Slime: enemigo básico. Patrulla al azar en idle, persigue al jugador en chase.
## Daño por contacto: su HitBox siempre activa inflige daño cuando toca al jugador.

const IDLE_MOVE_INTERVAL_MIN := 1.5
const IDLE_MOVE_INTERVAL_MAX := 3.0

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
	# 40% de probabilidad de quedarse quieto
	if randf() < 0.4:
		_idle_direction = Vector2.ZERO
	else:
		var angle := randf() * TAU
		_idle_direction = Vector2(cos(angle), sin(angle))

func _update_anim() -> void:
	if not _sprite.sprite_frames:
		return
	var anim := "walk" if velocity.length_squared() > 4.0 else "idle"
	if _sprite.sprite_frames.has_animation(anim) and _sprite.animation != anim:
		_sprite.play(anim)
