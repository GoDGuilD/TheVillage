extends Node
## Bus centralizado de señales. Desacopla emisores de receptores.
## Regla: solo señales aquí, cero lógica. Un autoload no llama a otro autoload.

# ─── Jugador ──────────────────────────────────────────────────────────────────
signal player_health_changed(current: int, maximum: int)
signal player_died()

# ─── Enemigos ─────────────────────────────────────────────────────────────────
signal enemy_died(enemy: Node2D)

# ─── Juego ────────────────────────────────────────────────────────────────────
signal game_over()
signal game_paused(is_paused: bool)

# ─── Salas (Fase 4) ───────────────────────────────────────────────────────────
signal room_entered(room_id: String)
signal room_exited(room_id: String)

# ─── Audio (Fase 3) ───────────────────────────────────────────────────────────
signal sfx_requested(sound_id: String)
signal music_requested(track_id: String)
