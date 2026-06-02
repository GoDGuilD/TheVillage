extends Node
## Bus centralizado de señales. Desacopla emisores de receptores.
## Regla: solo señales aquí, cero lógica. Un autoload no llama a otro autoload.

# ─── Jugador ──────────────────────────────────────────────────────────────────
@warning_ignore("unused_signal")
signal player_health_changed(current: int, maximum: int)
@warning_ignore("unused_signal")
signal player_died()

# ─── Enemigos ─────────────────────────────────────────────────────────────────
@warning_ignore("unused_signal")
signal enemy_died(enemy: Node2D)

# ─── Juego ────────────────────────────────────────────────────────────────────
@warning_ignore("unused_signal")
signal game_over()
@warning_ignore("unused_signal")
signal game_paused(is_paused: bool)

# ─── Salas (Fase 4) ───────────────────────────────────────────────────────────
@warning_ignore("unused_signal")
signal room_entered(room_id: String)
@warning_ignore("unused_signal")
signal room_exited(room_id: String)

# ─── Audio (Fase 3) ───────────────────────────────────────────────────────────
@warning_ignore("unused_signal")
signal sfx_requested(sound_id: String)
@warning_ignore("unused_signal")
signal music_requested(track_id: String)
