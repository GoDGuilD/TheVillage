extends Node
## Global game state. Orchestrates transitions between high-level states.
## Contains no gameplay logic — only coordinates which system is active.

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }

var state: GameState = GameState.MENU
var player: CharacterBody2D = null
var active_enemies: Array[Node] = []

## Player health saved between rooms.
## -1 = no previous data → the player uses their max_health when spawning in the new room.
var player_health: int = -1

# ─── Player ───────────────────────────────────────────────────────────────────

func register_player(p: CharacterBody2D) -> void:
	player = p
	state = GameState.PLAYING

func get_player() -> CharacterBody2D:
	return player

## Saves the player's current health before a room change.
## Called by SceneManager right before freeing the current scene.
func save_player_health() -> void:
	if not player:
		return
	var health := player.get_node_or_null("HealthComponent") as HealthComponent
	## Only save if the player is alive — if dead (0 HP), don't overwrite
	## the -1 that _on_player_died() already set to force max_health on respawn.
	if health and health.current_health > 0:
		player_health = health.current_health

# ─── Enemies ──────────────────────────────────────────────────────────────────

func register_enemy(enemy: Node) -> void:
	if not active_enemies.has(enemy):
		active_enemies.append(enemy)

func unregister_enemy(enemy: Node) -> void:
	active_enemies.erase(enemy)

func get_enemy_count() -> int:
	return active_enemies.size()

# ─── State ────────────────────────────────────────────────────────────────────

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
	## Reset the saved health so the next spawn uses max_health.
	## Without this, save_player_health() would save 0 (dead) and the player would respawn with no health.
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
