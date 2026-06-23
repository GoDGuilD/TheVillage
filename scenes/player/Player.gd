extends CharacterBody2D
class_name Player
## PlayerController — orchestrates movement, animation, combat and damage.
##
## Has no _physics_process of its own: StateMachine calls state_X_update(delta)
## every physics frame depending on the active state.
##
## States:
##   idle      → walk (there's input)
##   walk      → idle (no input) | attack (button)
##   attack    → idle (timer)
##   knockback → idle (timer) — only if alive
##   dead      — terminal, never exits

# ─── Nodes ────────────────────────────────────────────────────────────────────

@onready var _fsm:               StateMachine    = $StateMachine
@onready var _sprite:            AnimatedSprite2D = $AnimatedSprite2D
@onready var _health:            HealthComponent  = $HealthComponent
@onready var _hurt_box:          HurtBox          = $HurtBox
@onready var _sword_area:        Node2D           = $SwordArea
@onready var _sword_sprite:      Sprite2D         = $SwordArea/Sprite2D
@onready var _sword_hit_box:     HitBox           = $SwordArea/HitBox
@onready var _attack_timer:      Timer            = $AttackTimer
@onready var _invincibility_timer: Timer          = $InvincibilityTimer
@onready var _knockback_timer:   Timer            = $KnockbackTimer

# ─── Movement state ───────────────────────────────────────────────────────────

var _facing: Vector2 = Vector2.DOWN
var _knockback_velocity: Vector2 = Vector2.ZERO
var _is_invincible: bool = false

# ─── Init ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	GameManager.register_player(self)
	## Re-enable input — may be disabled if we're coming from a Game Over
	## (state_dead_enter turns it off and InputHandler persists between scenes as an autoload).
	InputHandler.controller_enabled = true
	## Restore health if the player is coming from another room.
	## GameManager.player_health = -1 means "use max_health" (start of game).
	if GameManager.player_health >= 0:
		_health.current_health = GameManager.player_health
		GameManager.player_health = -1  # Clear for the next transition
	_hurt_box.hurt.connect(_on_hurt)
	_health.died.connect(_on_died)
	_health.health_changed.connect(_on_health_changed)
	_attack_timer.timeout.connect(_on_attack_timer_done)
	_invincibility_timer.timeout.connect(_on_invincibility_done)
	_knockback_timer.timeout.connect(_on_knockback_done)
	InputHandler.attack_pressed.connect(_on_attack_pressed)
	## monitoring=false: the sword doesn't detect others. monitorable=false: nobody detects the sword.
	## Both are enabled together in state_attack_enter() to avoid the phantom-damage bug.
	_sword_hit_box.monitoring = false
	_sword_hit_box.monitorable = false
	_fsm.init(self, "idle")
	PlaceholderSprite.inject(_sprite, Color(0.259, 0.522, 0.957), Vector2i(12, 14))

# ═══════════════════════════════════════════════════════════════════════════════
# STATES
# ═══════════════════════════════════════════════════════════════════════════════

# ─── IDLE ─────────────────────────────────────────────────────────────────────

func state_idle_enter() -> void:
	_play_anim("idle")

func state_idle_update(delta: float) -> void:
	_decelerate(delta)
	if InputHandler.is_moving():
		_fsm.transition_to("walk")

# ─── WALK ─────────────────────────────────────────────────────────────────────

func state_walk_enter() -> void:
	_play_anim("walk")

func state_walk_update(delta: float) -> void:
	var dir := InputHandler.get_move_vector()
	if dir == Vector2.ZERO:
		_fsm.transition_to("idle")
		return
	_facing = dir
	_accelerate(dir, delta)
	_play_anim("walk")   # updates the direction suffix in real time

# ─── ATTACK ───────────────────────────────────────────────────────────────────

func state_attack_enter() -> void:
	velocity = Vector2.ZERO
	_position_sword()
	## Rotate the sword toward the attack direction and make it visible.
	_sword_area.rotation = _facing.angle()
	_sword_sprite.visible = true
	## Enable both: the sword detects and can be detected (activates the full hitbox).
	_sword_hit_box.monitoring = true
	_sword_hit_box.monitorable = true
	_attack_timer.start(Constants.PLAYER_ATTACK_DURATION)
	_play_anim("attack")

func state_attack_update(_delta: float) -> void:
	move_and_slide()  # collides with the world but without movement input

func state_attack_exit() -> void:
	_sword_sprite.visible = false
	_sword_area.rotation = 0.0
	## Disable both when exiting the attack state.
	_sword_hit_box.monitoring = false
	_sword_hit_box.monitorable = false

# ─── KNOCKBACK ────────────────────────────────────────────────────────────────

func state_knockback_enter() -> void:
	_knockback_timer.start(Constants.KNOCKBACK_DURATION)

func state_knockback_update(delta: float) -> void:
	## Applies knockback velocity with exponential deceleration.
	velocity = _knockback_velocity
	_knockback_velocity = _knockback_velocity.move_toward(
		Vector2.ZERO,
		Constants.KNOCKBACK_FORCE * 6.0 * delta
	)
	move_and_slide()

func state_knockback_exit() -> void:
	_knockback_velocity = Vector2.ZERO
	velocity = Vector2.ZERO

# ─── DEAD ─────────────────────────────────────────────────────────────────────

func state_dead_enter() -> void:
	InputHandler.controller_enabled = false
	_sword_hit_box.monitoring = false
	_sprite.modulate.a = 1.0
	_play_anim("idle")   # final frame: idle facing down
	velocity = Vector2.ZERO

func state_dead_update(_delta: float) -> void:
	pass   # terminal — never exits this state

# ═══════════════════════════════════════════════════════════════════════════════
# INTERNAL MOVEMENT
# ═══════════════════════════════════════════════════════════════════════════════

func _accelerate(dir: Vector2, delta: float) -> void:
	velocity = velocity.move_toward(
		dir * Constants.PLAYER_SPEED,
		Constants.PLAYER_ACCELERATION * delta
	)
	move_and_slide()

func _decelerate(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, Constants.PLAYER_FRICTION * delta)
	move_and_slide()

# ═══════════════════════════════════════════════════════════════════════════════
# ATTACK
# ═══════════════════════════════════════════════════════════════════════════════

func _on_attack_pressed() -> void:
	if _fsm.current_state == "idle" or _fsm.current_state == "walk":
		_fsm.transition_to("attack")

func _on_attack_timer_done() -> void:
	_fsm.transition_to("idle")

func _position_sword() -> void:
	_sword_area.position = _facing.normalized() * Constants.PLAYER_SWORD_REACH

# ═══════════════════════════════════════════════════════════════════════════════
# DAMAGE AND HEALTH
# ═══════════════════════════════════════════════════════════════════════════════

func _on_hurt(damage: int, source_position: Vector2) -> void:
	if _is_invincible or _fsm.current_state == "dead":
		return
	_health.take_damage(damage)
	_start_invincibility()
	if _health.is_alive():
		_start_knockback(source_position)

func _start_knockback(source_position: Vector2) -> void:
	## Knockback direction goes from the attacker to the player (we move away from the hit).
	var dir := (global_position - source_position).normalized()
	if dir == Vector2.ZERO:
		dir = -_facing.normalized()
	_knockback_velocity = dir * Constants.KNOCKBACK_FORCE
	_fsm.transition_to("knockback")

func _on_knockback_done() -> void:
	if _health.is_alive():
		_fsm.transition_to("idle")

func _start_invincibility() -> void:
	_is_invincible = true
	_invincibility_timer.start(Constants.PLAYER_IFRAMES_DURATION)
	_flash_sprite()

func _flash_sprite() -> void:
	var tween := create_tween().set_loops(5)
	tween.tween_property(_sprite, "modulate:a", 0.15, 0.07)
	tween.tween_property(_sprite, "modulate:a", 1.0,  0.07)

func _on_invincibility_done() -> void:
	_is_invincible = false
	_sprite.modulate.a = 1.0

func _on_died() -> void:
	_fsm.transition_to("dead")
	EventBus.player_died.emit()

func _on_health_changed(current: int, maximum: int) -> void:
	EventBus.player_health_changed.emit(current, maximum)

# ═══════════════════════════════════════════════════════════════════════════════
# ANIMATION
# ═══════════════════════════════════════════════════════════════════════════════

func _play_anim(base: String) -> void:
	var anim := base + "_" + _dir_suffix()
	if _sprite.sprite_frames and _sprite.sprite_frames.has_animation(anim):
		if _sprite.animation != anim:
			_sprite.play(anim)

func _dir_suffix() -> String:
	## Quantizes the analog direction to 4 cardinal directions to pick the animation.
	if absf(_facing.y) >= absf(_facing.x):
		return "up" if _facing.y < 0.0 else "down"
	return "left" if _facing.x < 0.0 else "right"
