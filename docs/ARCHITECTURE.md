<!--
File: ARCHITECTURE.md
Description: Code architecture of The Village: folders, autoloads, contracts, player states, physics layers.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-05-26
Last edit date: 2026-10-15
Version: 4.0.0
-->

# Architecture

The project was rebuilt on 2026-10-15 on the architecture of *Chapel of Dreams* (game 2 of the trilogy). The 2026
prototype (EventBus/GameManager/SceneManager/InputHandler) is in git history up to commit `cec47ca`.

## Folders
```
src/
  core/      StateMachine, SpriteStrips (PNG strips -> SpriteFrames), HitFlash,
             GameState / Audio / Juice (autoloads)
  combat/    HitBox (deals damage; `blockable`), HurtBox (receives it, emits `hurt`), HealthComponent
  player/    Player.gd/.tscn (children built in code), PlayerTuning (every feel constant)
  enemies/   BaseEnemy, Slime, Guard, Spitter, EnemyRock
  world/     TestField (ASCII layout -> TileMapLayer + actors + HUD), Bush, Pot, Thrown, Pickup
  ui/        Hud (hearts + gem counter)
tools/       palette.py, sprite_lib.py, gen_joe.py, gen_tiles.py, gen_enemies.py, gen_props.py, gen_sfx.py,
             capture_field.gd
tests/       test_player.gd, test_combat.gd
```

## Autoloads (order in project.godot)
| Autoload | Role |
|---|---|
| `GameState` | Run state: gems, the drop table (`roll_drop`, `drops_enabled`, `force_drop`) |
| `Audio` | Pooled one-shot SFX on an `SFX` bus (`sfx(name)`, `history` for tests) |
| `Juice` | Camera shake, per-actor hit-stop (`freeze(seconds)` on actors), one-shot effects from `assets/sprites/vfx` |

## Key ideas
- **Generated art and sound.** `tools/gen_*.py` draw every sprite/tile from `tools/palette.py` and synthesise every
  sound; each writes a manifest the game reads at runtime.
- **Runtime TileSet** from `overworld_light.json`; solid cells get a full-square polygon.
- **Feet origin.** Actors' node origin is under their feet; only a small feet box collides with the world. The
  `Actors` node is y-sorted.
- **Combat contract.** A `HitBox` only hurts while `monitorable` (`set_active`). A `HurtBox` emits
  `hurt(damage, source_position, knockback)` and remembers `last_hit`. Bushes, enemies and Joe all use it.
- **Shield.** Joe's `_on_hurt` checks `last_hit.blockable` and `blocks_from(source)` first; a blocked projectile is
  told to `deflect()`.
- **Liftable contract.** Nodes in group `liftable` implement `can_lift()` and `lift() -> {kind, texture}` (Pot, Bush).
  Joe carries a sprite; throwing spawns a `Thrown` body that moves along the ground while its sprite arcs.
- **Pickup contract.** `Pickup` calls `collect(kind)` on the body that touches it (Joe).
- **Enemies** extend `BaseEnemy`: set `pack`/stats in `_init()`, write the AI in `_think(delta)`, move with
  `_move()`. Knockback, i-frames, flash, hit-stop, death puff and drops are shared.

## Player state machine
`idle` / `walk` → `attack` (sword live on the manifest's hit window; a press buffers a chained slash; holding
continues into) → `charge` (shuffle, facing locked, glint when charged) → `spin` (circle hit box) → `idle`.
`idle` / `walk` → `lift` (interact on a liftable) → `carry` → `throw` → `idle`. Any state → `hurt` on a hit
(knockback, then `idle`; i-frames and blinking run outside the state machine) or → `dead` at zero health (the
field revives Joe at its spawn). A hit-stop pauses the state machine and the animation for a few frames.

## Physics layers
| # | Name | Value | Used by |
|---|---|---|---|
| 1 | World | 1 | solid tiles (rocks, trees) |
| 2 | Player | 2 | Joe's body (pickups detect it) |
| 3 | Enemies | 4 | enemy bodies (collide with world + props only) |
| 4 | PlayerHitBox | 8 | sword, spin, thrown objects |
| 5 | EnemyHitBox | 16 | enemy contact, enemy rocks |
| 6 | PlayerHurtBox | 32 | Joe's hurt box |
| 7 | EnemyHurtBox | 64 | enemy hurt boxes |
| 8 | Props | 128 | bushes and pots (solid to Joe and enemies) |

## Display
384×216 viewport, `canvas_items` stretch, integer scale, nearest filter, pixel-snapped transforms,
`gl_compatibility`. The camera is a child of Joe limited to the field (screen-edge scrolling comes in Phase 3);
the HUD is a CanvasLayer (layer 10).
