<!--
File: ARCHITECTURE.md
Description: Code architecture of The Village: folders, autoloads, contracts, player states, physics layers.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-05-26
Last edit date: 2026-10-15
Version: 5.1.0
-->

# Architecture

The project was rebuilt on 2026-10-15 on the architecture of *Chapel of Dreams* (game 2 of the trilogy). The 2026
prototype (EventBus/GameManager/SceneManager/InputHandler) is in git history up to commit `cec47ca`.

## Folders
```
src/
  core/      StateMachine, SpriteStrips (PNG strips -> SpriteFrames), HitFlash, SaveGame (JSON save file),
             DialogueData (dialogue.json reader), GameState / Audio / Juice (autoloads)
  combat/    HitBox (deals damage; `blockable`), HurtBox (receives it, emits `hurt`), HealthComponent
  player/    Player.gd/.tscn (children built in code), PlayerTuning (every feel constant)
  enemies/   BaseEnemy, Slime, Guard, Spitter, EnemyRock
  world/     World (areas, camera, scrolls, doors, HUD, dialogue, menus, Game Over, saving), AreaBuilder (ASCII rows ->
             tiles + actors), TestField (test arenas), Npc, SignPost, Bush, Pot, Thrown, Pickup
    areas/   generated area JSON (index.json + one file per area) - written by tools/gen_areas.py
  ui/        TitleScreen (main scene), Hud, DialogueBox, PauseMenu, ItemMenu, GameOver, MenuList, PixelText,
             UiTheme (colours, layers, box helpers)
assets/data/ dialogue.json (every villager line and sign text)
tools/       palette.py, sprite_lib.py, terrain_art.py, font_glyphs.py, gen_joe.py, gen_tiles.py, gen_enemies.py,
             gen_props.py, gen_ui.py, gen_npcs.py, gen_sfx.py, gen_areas.py (areas + lint + preview),
             capture_field.gd, capture_world.gd, capture_ui.gd
tests/       test_player.gd, test_combat.gd, test_world.gd, test_ui.gd
```

## Autoloads (order in project.godot)
| Autoload | Role |
|---|---|
| `GameState` | Run state: gems, magic, keys, items, equipped item, family seals, story flags, the drop table; `snapshot()` / `restore()` for saves |
| `Audio` | Pooled one-shot SFX on an `SFX` bus (`sfx(name)`, `history` for tests) |
| `Juice` | Camera shake, per-actor hit-stop (`freeze(seconds)` on actors), one-shot effects from `assets/sprites/vfx` |

## Key ideas
- **Generated art and sound.** `tools/gen_*.py` draw every sprite/tile from `tools/palette.py` and synthesise every
  sound; each writes a manifest the game reads at runtime.
- **Runtime TileSet** (`AreaBuilder.tileset()`) from `overworld_light.json`: solid cells get a full-square polygon;
  `ledge`/`door`/`exit` flags become custom-data layers that Joe and the World query (`AreaBuilder.flag_at`).
- **One global coordinate system.** Every overworld area sits at its `origin_tiles` on a grid of 24x14-tile screens,
  so neighbouring areas share edges. Only the current area exists in the tree; crossing an edge builds the
  neighbour, slides the camera for 0.6 s while Joe steps 14 px in, then frees the old area. Interiors sit far away
  (tile 1000+) and are reached by fading through doors / exit mats.
- **Camera.** A World-owned Camera2D follows Joe's chest, clamped to the area; an area smaller than the view (house
  interiors) is centred.
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

- **Talkable contract.** Nodes in group `talkable` implement `talk_point() -> Vector2`, `talk(from) -> String`
  (the dialogue key) and `rest()`. Joe's interact probes one tile ahead (`talkable_in_front()`) and talking wins
  over lifting; he emits `talk_requested(target)` and the World opens the `DialogueBox`.
- **Pausing.** Dialogue, the pause and item menus and Game Over set `get_tree().paused`; their CanvasLayers run
  with `PROCESS_MODE_ALWAYS` (as do `Audio` and `MenuList`). After a conversation Joe is frozen for 0.15 s so the
  closing press cannot start the talk again.
- **Scenes and saves.** `TitleScreen` is the main scene. CONTINUE reads the save into `SaveGame.pending`; the
  World applies it before building the first area (area, entry point, facing, hearts, GameState snapshot). Saves
  are made at the current area's entry point, so a loaded game never starts mid-fight.

## Player state machine
`idle` / `walk` → `attack` (sword live on the manifest's hit window; a press buffers a chained slash; holding
continues into) → `charge` (shuffle, facing locked, glint when charged) → `spin` (circle hit box) → `idle`.
`walk` → `hop` (walking south into a ledge: a 0.35 s arc to the first open cell past it, no collision).
`idle` / `walk` → `lift` (interact on a liftable; a talkable in front takes priority) → `carry` → `throw` → `idle`.
Any state → `hurt` on a hit (knockback, then `idle`; i-frames and blinking run outside the state machine) or →
`dead` at zero health (the World shows Game Over; a test field revives Joe at its spawn). A hit-stop pauses the state machine and the animation for a few frames.

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
`gl_compatibility`. The World's camera follows Joe inside the area and slides between areas; test arenas keep a
camera on Joe limited to the field. CanvasLayers (`UiTheme`): HUD 10, dialogue 14, menus 16, Game Over 18,
door fade 20.
