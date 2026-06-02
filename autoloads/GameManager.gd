extends Node
## Estado global del juego. Orquesta transiciones entre estados de alto nivel.
## No contiene lógica de gameplay — solo coordina qué sistema está activo.

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }

var state: GameState = GameState.MENU
var player: CharacterBody2D = null
var active_enemies: Array[Node] = []

## Vida del jugador guardada entre salas.
## -1 = sin datos previos → el jugador usa su max_health al nacer en la nueva sala.
var player_health: int = -1

# ─── Jugador ──────────────────────────────────────────────────────────────────

func register_player(p: CharacterBody2D) -> void:
	player = p
	state = GameState.PLAYING

func get_player() -> CharacterBody2D:
	return player

## Guarda la vida actual del jugador antes de un cambio de sala.
## Llamado por SceneManager justo antes de liberar la escena actual.
func save_player_health() -> void:
	if not player:
		return
	var health := player.get_node_or_null("HealthComponent") as HealthComponent
	## Solo guardar si el jugador está vivo — si está muerto (0 HP) no sobreescribir
	## el -1 que _on_player_died() ya estableció para forzar max_health al renacer.
	if health and health.current_health > 0:
		player_health = health.current_health

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
	## Resetear la vida guardada para que el próximo spawn use max_health.
	## Sin esto, save_player_health() guardaría 0 (muerto) y el jugador renacería sin vida.
	player_health = -1

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
