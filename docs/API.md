<!--
File: API.md
Description: Internal scripting API of the main classes.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-15
Version: 1.0.0
-->

# API

The game has no network API; this is the internal API other scripts and tests rely on.

## Player (`src/player/Player.gd`)
- Signals: `health_changed(current, maximum)`, `died`.
- Properties: `facing: Vector2i` (cardinal), `health: HealthComponent`, `sprite`, `sword: HitBox`, `hurt_box: HurtBox`, `fsm: StateMachine` (states `idle`, `walk`, `attack`, `hurt`), `_input_override` (tests: a Vector2 replaces the keyboard).
- `is_invincible() -> bool`.

## TestField (`src/world/TestField.gd`)
- `layout: Array[String]` (assign before entering the tree), `player`, `bushes`, `tiles: TileMapLayer`, `actors: Node2D` (y-sorted), `field_size() -> Vector2i`.

## Bush (`src/world/Bush.gd`)
- Signal `cut(at: Vector2)`; `is_cut()`.

## Combat
- `HitBox`: `damage`, `knockback`, `element`, `set_active(on)`, signal `landed(hurt_box)`.
- `HurtBox`: signal `hurt(damage, source_position, knockback)`, `recheck()`, `last_hit`.
- `HealthComponent`: `max_health`, `current_health`, `take_damage()`, `heal()`, `is_alive()`, signals `health_changed`, `died`.
- `StateMachine`: `init(host, initial)`, `transition_to(state)`, `current_state`, signal `state_changed`.
