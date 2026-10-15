<!--
File: ARCHITECTURE.md
Description: Code architecture of The Village after the 2026-10 rebuild: folders, nodes, physics layers, data flow.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-05-26
Last edit date: 2026-10-15
Version: 3.0.0
-->

# Architecture

The project was rebuilt on 2026-10-15 on the architecture of *Chapel of Dreams* (game 2 of the trilogy). The
2026 prototype (scenes/, scripts/, autoloads/ with EventBus/GameManager/SceneManager/InputHandler) was retired;
it remains in git history up to commit `cec47ca`.

## Folders
```
src/
  core/      StateMachine (state_X_enter/update/exit by naming), SpriteStrips (PNG strips -> SpriteFrames), HitFlash
  combat/    HitBox (deals damage), HurtBox (receives it, emits `hurt`), HealthComponent
  player/    Player.gd/.tscn (children built in code), PlayerTuning (every feel constant)
  world/     TestField (ASCII layout -> TileMapLayer + actors), Bush
tools/       palette.py, sprite_lib.py, gen_joe.py, gen_tiles.py (art generators), capture_field.gd (screenshots)
tests/       test_player.gd (headless suite)
assets/      sprites/joe, sprites/world, tiles (generated) - reference/, branding/, audio/ (recovered 2024 material)
docs/        this documentation set
```

## Key ideas
- **Generated art.** `tools/gen_*.py` draw every sprite/tile from `tools/palette.py`; each writes a JSON manifest
  next to its PNGs (frame size, feet point, fps, loop, slash hit window; tile names + solidity). Godot reads the
  manifests at runtime, so art and code never drift apart.
- **Runtime TileSet.** `TestField._build_tileset()` turns `overworld_light.json` into a TileSet with one physics
  layer; solid cells get a full-square polygon. No `.tres` to keep in sync.
- **Feet origin.** Actors' node origin is the point under their feet; only a small box around the feet collides
  with the world (ALttP style). The `Actors` node is y-sorted.
- **Player children are built in code** (`Player._build_children`), so `Player.tscn` is a one-node scene and all
  numbers come from `PlayerTuning`.
- **Combat contract.** A `HitBox` only hurts while `monitorable` (toggled per slash frame via `set_active`); a
  `HurtBox` emits `hurt(damage, source_position, knockback)`. Bushes are cut through the same contract.

## Player state machine
`idle` ↔ `walk` → `attack` (sword live on manifest hit-window frames; a press during the slash buffers a chained
slash) → `idle`/`walk`. Any state → `hurt` on a hit (knockback for `HURT_TIME`, then `idle`); i-frames and
blinking are handled in `_physics_process` independent of the state.

## Physics layers
| # | Name | Value | Used by |
|---|---|---|---|
| 1 | World | 1 | solid tiles (rocks, trees) |
| 2 | Player | 2 | Joe's body |
| 3 | Enemies | 4 | (Phase 2) |
| 4 | PlayerHitBox | 8 | the sword |
| 5 | EnemyHitBox | 16 | (Phase 2) |
| 6 | PlayerHurtBox | 32 | Joe's hurt box |
| 7 | EnemyHurtBox | 64 | (Phase 2) |
| 8 | Cuttable | 128 | bushes (solid to Joe, cut by the sword) |

## Display
384×216 viewport, `canvas_items` stretch, integer scale, nearest filter, 2D transforms snapped to pixels,
`gl_compatibility` renderer. The camera is a child of Joe limited to the field rectangle (ALttP screen-edge
scrolling arrives with the overworld engine in Phase 3).
