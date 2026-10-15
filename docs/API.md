<!--
File: API.md
Description: Internal scripting API of the main classes.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-15
Version: 1.1.0
-->

# API

The game has no network API; this is the internal API other scripts and tests rely on.

## Player (`src/player/Player.gd`)
- Signals: `health_changed(current, maximum)`, `died`.
- Properties: `facing: Vector2i`, `health`, `sprite`, `sword: HitBox`, `spin_box: HitBox`, `hurt_box`, `fsm`
  (states `idle walk attack charge spin lift carry throw hurt dead`), `charged`, `carrying` (`""`, `"pot"`, `"bush"`),
  `_input_override` (tests).
- Calls: `is_invincible()`, `is_dead()`, `freeze(seconds)`, `blocks_from(source_position)`, `liftable_in_front()`,
  `revive(at)`, `collect(kind)`.

## Enemies (`src/enemies/`)
- `BaseEnemy`: signal `defeated(at)`; `player` (set by the field), `health`, `facing`, `freeze()`, `is_dead()`;
  static `spawn_drop(parent, at)`.
- `Guard.chasing`, `Spitter.spit()` / `shots`, `EnemyRock.deflect()` / `deflected`.

## World (`src/world/`)
- `TestField`: `layout`, `spawn_enemies`, `player`, `hud`, `bushes`, `pots`, `enemies`, `spawn_point`, `deaths`,
  `field_size()`.
- `Bush`: signal `cut(at)`, `is_cut()`, liftable. `Pot`: liftable. Liftable contract: `can_lift()`, `lift()`.
- `Thrown`: signal `broke(at)`; `kind`, `direction`, `travel`, `damage`. `Pickup`: `kind`, signal `collected(kind)`.

## Autoloads
- `GameState`: signal `gems_changed(amount)`; `gems`, `add_gems()`, `roll_drop()`, `drops_enabled`, `force_drop`,
  `reset()`, `GEM_VALUES`.
- `Audio`: `sfx(name, pitch, volume_db, jitter)`, `played_recently(name, n)`, `history`, `last_sfx`.
- `Juice`: `shake(px, seconds)`, `hit_stop(actors, seconds)`, `play_fx(name, pos, parent)`, `fx_count`,
  `last_hit_stop`.

## Combat
- `HitBox`: `damage`, `knockback`, `element`, `blockable`, `set_active(on)`, signal `landed(hurt_box)`.
- `HurtBox`: signal `hurt(damage, source_position, knockback)`, `recheck()`, `last_hit`.
- `HealthComponent`, `StateMachine`: as ported from Chapel of Dreams.

## UI
- `Hud`: `set_health(current, maximum)`, `set_gems(amount)`, `hearts_shown` (e.g. `"FHE"`), `gems_shown`.
