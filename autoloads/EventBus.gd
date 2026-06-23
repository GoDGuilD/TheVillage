extends Node
## Centralized signal bus. Decouples emitters from receivers.
## Rule: signals only here, zero logic. No autoload calls another autoload.

# ─── Player ───────────────────────────────────────────────────────────────────
@warning_ignore("unused_signal")
signal player_health_changed(current: int, maximum: int)
@warning_ignore("unused_signal")
signal player_died()

# ─── Enemies ──────────────────────────────────────────────────────────────────
@warning_ignore("unused_signal")
signal enemy_died(enemy: Node2D)

# ─── Game ─────────────────────────────────────────────────────────────────────
@warning_ignore("unused_signal")
signal game_over()
@warning_ignore("unused_signal")
signal game_paused(is_paused: bool)

# ─── Rooms (Phase 4) ──────────────────────────────────────────────────────────
@warning_ignore("unused_signal")
signal room_entered(room_id: String)
@warning_ignore("unused_signal")
signal room_exited(room_id: String)

# ─── Audio (Phase 3) ──────────────────────────────────────────────────────────
@warning_ignore("unused_signal")
signal sfx_requested(sound_id: String)
@warning_ignore("unused_signal")
signal music_requested(track_id: String)
