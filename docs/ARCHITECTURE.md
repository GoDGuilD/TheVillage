<!--
File: ARCHITECTURE.md
Description: Code architecture of The Village: folders, autoloads, contracts, player states, physics layers.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-05-26
Last edit date: 2026-10-23
Version: 5.8.0
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
  enemies/   BaseEnemy, Slime, Guard, Spitter, Bat, Lurker, Cinder, Cogbug, EnemyRock, EnemyShot, bosses:
             GrandSlime, IronRam, FrostWraith, CaverShade (+ CaverOrb), GloomMoth, MagmaWyrm, ClockWarden
  items/     ItemDB (catalogue + wares), ItemUse (item button), Boomerang, Arrow, Bomb, Fireball, Grapple, IceBolt, HammerBlow
  world/     World (areas, camera, scrolls, doors, HUD, dialogue, menus, Game Over, saving), AreaBuilder (ASCII rows ->
             tiles + actors), TestField (test arenas), Npc, SignPost, Chest, BigChest, Torch, CrackedRock, KeyBlock,
             ShopItem, Door, FloorSwitch, PushBlock, HeavyRock, Rubble, SealGate, Rift, HookPost, GroundFlame, Peg, TickBlock,
             Bush, Pot, Thrown, Pickup
    areas/   generated area JSON (index.json + one file per area) - written by tools/gen_areas.py
  ui/        TitleScreen (main scene), Hud, DialogueBox, PauseMenu, ItemMenu, MapScreen, GameOver, EndCard, MenuList,
             PixelText,
             UiTheme (colours, layers, box helpers)
assets/data/ dialogue.json (every villager line and sign text)
tools/       palette.py, sprite_lib.py, terrain_art.py, dungeon_art.py, font_glyphs.py, gen_joe.py, gen_tiles.py, gen_enemies.py,
             gen_props.py, gen_ui.py, gen_npcs.py, gen_items.py, gen_dungeon.py, gen_act1.py, gen_dark.py, gen_umbra.py, gen_ignis.py (+ ignis_art.py), gen_tempus.py, gen_sfx.py, gen_areas.py (areas + lint + preview),
             capture_field.gd, capture_world.gd, capture_ui.gd, capture_items.gd, capture_dungeon.gd, capture_act1.gd, capture_dark.gd, capture_umbra.gd, capture_ignis.gd, capture_tempus.gd
tests/       test_player.gd, test_combat.gd, test_world.gd, test_ui.gd, test_items.gd, test_dungeon.gd,
             test_act1.gd, test_dark.gd, test_umbra.gd, test_ignis.gd, test_tempus.gd
```

## Autoloads (order in project.godot)
| Autoload | Role |
|---|---|
| `GameState` | Run state: gems, magic, keys, items, equipped item, family seals, dimension crystals, story flags, the drop table; `snapshot()` / `restore()` for saves |
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

- **Items.** The item button puts Joe in state `use` (0.2 s throw pose) and calls `ItemUse.use(player, item, aim)`,
  which spends ammo/magic and spawns a `Boomerang` / `Arrow` / `Bomb` into Joe's parent, or lights a `Torch`.
  The boomerang's HitBox has `element = "stun"` (BaseEnemy freezes instead of taking damage); bombs carry two
  HitBoxes (PlayerHitBox for enemies and bushes, EnemyHitBox for Joe) and call `blast()` on group `bombable`.
- **Interactions.** Chests, key blocks and shop wares are talkables too; the World dispatches on their class
  (`Chest` -> item-get, `KeyBlock` -> spend a key or "locked", `ShopItem` -> BUY / NO offer) before plain talk.
  `item_get(kind)` grants via `grant()`, has Joe `hold_up()` the icon and shows the kind's text; the dialogue's
  `_after_dialogue` callable lowers it (and hands over a villager's gift after their lines).
- **Persistence of the world.** Opened chests, broken cracked rocks, opened key blocks, taken heart pieces and
  sold-out wares are GameState flags (`<kind>:<area>:<x>,<y>`, `ware:<id>`), consulted when an area is built.

- **Dungeons.** A dungeon is a set of `kind: "dungeon"` areas on their own room grid (`DUNGEON_BASE`) sharing a
  `dungeon` id; `group_of()` puts them in one scroll group (the overworld is another). The index lists each
  dungeon's name, entrance, boss room, boss flag and seal number. On every area change the World sets the key pool
  and the visited flag, closes the boss door behind Joe, and each frame checks the room's `clear_flag`. Doors are
  built open or shut from flags; shutters open when their `when` flag is set (room cleared, switch pressed, boss).
- **Bosses and weaknesses.** `BaseEnemy._resists(hit)` runs before stun and damage; a resisted hit clanks. The
  Iron Ram resists unless dazed, the Frost Wraith unless the HitBox element is "fire", Caver's shade unless it
  is "orb" (an orb Joe batted back). Bosses carry `is_boss`; the World connects their `defeated` signal. A dungeon
  whose table entry has `ending` (the keep) ends the act instead of giving a reward (`World.play_ending`).
- **Two worlds.** Each overworld area has a Dark World twin (`world: "dark"`, id `dw_<id>`) at the same
  coordinates, in the group `overworld_dark`; AreaBuilder paints it with the dark TileSet (`tileset(true)`, same
  cells, `overworld_dark.png`). Because the coordinates match, the Moon Mirror and the rifts just call
  `_world_warp(group, mirror)`: rebuild the area of the other group under Joe's feet; the mirror checks the tile
  under him (`_solid_at`) and bounces back, or leaves a portal `Rift` that returns him.
- **Dimensions (Umbra).** Dark World-only lands (`DARK_ONLY`) have no Light World twin, so the mirror refuses
  there. Rooms flagged `"dark"` show `World.darkness`: a world-space sprite (z 100, above every actor, below the
  CanvasLayers) centred on Joe - a night with a soft hole, small or lantern-sized - until all the room's torches
  burn (`update_darkness`). Crystal dungeons carry `crystal` instead of `seal`; `_spawn_boss_reward` hands out
  the crystal after the heart container.
- **The grapple.** `Grapple` flies over cells flagged `low` (water, pits), stops at other solids and bodies, and
  latches onto the nearest `hookable` (`HookPost.hook_point()`); it then calls `Player.grapple_pull(to, hook)`:
  state `pulled` drops Joe's collision mask and slides him to the cell in front of the post, then releases the
  grapple. Its HitBox element `hook` stuns like the boomerang unless the enemy's `_hooked()` handles it (the Gloom
  Moth lands). The level lint mirrors this in `grapple_hops`.
- **Lava and ice (Ignis).** Lava cells carry `pit` (Joe falls in), `low` (the grapple flies over) and `lava`. An
  `IceBolt` calls `AreaBuilder.freeze_at` every frame: a lava cell under it becomes the `crust` cell (no flags, no
  collision) and a timer per cell puts the lava piece back; each freeze bumps a per-cell generation so only the
  newest timer thaws it. Element `ice` freezes ordinary enemies (`freeze` + a blue `self_modulate`) unless
  `_iced()` handles it - the Magma Wyrm turns it into its `frozen` state.
- **Tempus's clock.** Tick blocks and pegs are made by AreaBuilder from their glyphs (like bushes and pots), so they
  reset whenever an area is rebuilt. While the current area has tick blocks, `World._run_clock` counts down
  `TICK_TIME` and flips `tick_phase`; `_apply_ticks` raises the matching colour. A block asked to rise while Joe
  stands in its cell stays `pending` and rises once he leaves. Sunk blocks and flat pegs move their node up a few
  pixels so the y-sorted actors draw over them (a negative z_index would hide them under the ground).
- **Pits** are a TileSet flag (`pit`) Joe checks under his feet (state `fall`) and a second physics layer (9, Pits)
  that only enemies and push blocks collide with.

## Player state machine
`idle` / `walk` → `attack` (sword live on the manifest's hit window; a press buffers a chained slash; holding
continues into) → `charge` (shuffle, facing locked, glint when charged) → `spin` (circle hit box) → `idle`.
`walk` → `hop` (walking south into a ledge: a 0.35 s arc to the first open cell past it, no collision).
`idle` / `walk` → `lift` (interact on a liftable; a talkable in front takes priority) → `carry` → `throw` → `idle`.
`idle` / `walk` → `use` (item button) → `idle`; any → `hold` (item-get pose, ended by the World); `idle` / `walk`
→ `fall` (over a pit; the World takes a heart and calls `respawn_after_fall`); `idle` / `walk` → `dash_charge`
(dash button, boots) → `dash` (sword out; rubble breaks) → `bonk` on a wall → `idle`. `use` with the grapple
waits for the chain; a bite → `pulled` (no collision, slides to the post) → `idle`.
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
| 9 | Pits | 256 | pit cells - walls for enemies and push blocks only |

## Display
384×216 viewport, `canvas_items` stretch, integer scale, nearest filter, pixel-snapped transforms,
`gl_compatibility`. The World's camera follows Joe inside the area and slides between areas; test arenas keep a
camera on Joe limited to the field. CanvasLayers (`UiTheme`): HUD 10, dialogue 14, menus 16, Game Over 18,
door fade 20.
