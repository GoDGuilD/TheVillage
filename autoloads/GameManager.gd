extends Node
## Estado global del juego. Orquesta transiciones entre estados de alto nivel.
## No contiene lógica de gameplay — solo coordina qué sistema está activo.

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }

var state: GameState = GameState.MENU
var player: CharacterBody2D = null
var active_enemies: Array[Node] = []

# ─── Jugador ──────────────────────────────────────────────────────────────────

func register_player(p: CharacterBody2D) -> void:
	player = p
	state = GameState.PLAYING

func get_player() -> CharacterBody2D:
	return player

# ─── Enemigos ─────────────────────────────────────────────────────────────────

func register_enemy(enemy: Node) -> void:
	if not active_enemies.has(enemy):
		active_enemies.append(enemy)

func unregister_enemy(enemy: Node) -> void:
	active_enemies.erase(enemy)

func get_enemy_count() -> int:
	return active_enemies.size()

# ─── Estado ───────────────────────────────────────────────────────────────────

func set_state(new_state: GameState) -> void:
	if state == new_state:
		return
	state = new_state
	_on_state_changed(new_state)

func is_playing() -> bool:
	return state == GameState.PLAYING

func _ready() -> void:
	EventBus.player_died.connect(_on_player_died)
	EventBus.enemy_died.connect(_on_enemy_died)

func _on_player_died() -> void:
	set_state(GameState.GAME_OVER)

func _on_enemy_died(enemy: Node2D) -> void:
	unregister_enemy(enemy)

func _on_state_changed(new_state: GameState) -> void:
	match new_state:
		GameState.GAME_OVER:
			EventBus.game_over.emit()
		GameState.PAUSED:
			get_tree().paused = true
		GameState.PLAYING:
			get_tree().paused = false
