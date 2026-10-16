<!--
File: CHANGELOG.md
Description: Dated record of all relevant changes to The Village, reconstructed from git history and pre-repo project history.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-05-26
Last edit date: 2026-10-16
Version: 5.3.0
-->

# Changelog — The Village

All relevant project changes are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

> **Before this repo existed:** The Village began as a school project at UVM in
> February 2024 — a much larger narrative concept, built up across four
> different courses and finished as a working Unreal Engine 5 prototype in
> December 2024. This repo is a from-scratch reboot in Godot, deliberately
> scoped down to a lean prototype. See `LORE.md` for the original narrative
> and `technical_memory/technical_memory.ipynb` for the full recovered
> timeline and the reasoning behind this changelog's structure.

---

## [7.0.0] - 2026-10-16 — Phase 6: dungeon framework + the Moss Shrine

### Added
- The **Moss Shrine** (dungeon 1), entered through a stone shrine in the West Woods: eight one-screen rooms on
  their own grid (entrance with exit stairs, hub, west, northwest, east, northeast, antechamber, boss room) that
  scroll into each other like the overworld; Joe steps 40 px in, past the two-tile walls.
- Doors (`Door`): locked (a small key of this dungeon), big (the big key), shutters (open when a room flag is
  set: room cleared of enemies, or a floor switch) and the boss door (shuts behind Joe until the boss falls). A
  door shared by two rooms exists in both.
- `FloorSwitch` (heavy ones need a block), `PushBlock` (a steady push slides it one tile; presses switches),
  pits (Joe falls: one heart, back to the room's entry; enemies treat pits as walls via physics layer 9),
  `BigChest`, chests revealed by a switch, `HeavyRock` (lifted and thrown with the power glove).
- Dungeon items: map, compass, big key (per dungeon), small keys counted per dungeon (`GameState.key_pools`); the
  HUD shows the key counter at zero inside a dungeon.
- `MapScreen` (Tab): dungeon rooms (visited, or all with the map), Joe's room blinking, the boss room with the
  compass, dungeon items and keys; outside, the overworld areas visited, with their names.
- Boss: the **Grand Slime** (16 HP, hops at Joe, buds off up to 3 slimes when struck, faster at half health,
  immune to the boomerang's stun). Then a heart container, then the **first family seal**, then Joe is sent back
  out in front of the shrine.
- The **Power Glove** in the shrine's big chest; two heavy rocks now guard the East Lake piece of heart.
- Generators: `tools/dungeon_art.py` + `gen_tiles.py` v3 (113 cells: dungeon floor, walls, pillar, stairs, pit
  nine-slice, the shrine facade), `tools/gen_dungeon.py` (doors x4 sides, switch, block, big chest, heavy rock,
  seal, map/compass/big key/glove icons, the Grand Slime pack), `gen_sfx.py` + fall, shutter, switch_click,
  block_push, boss_die (42 effects). `gen_areas.py` v3: dungeon rooms, groups, door/switch/block/big-chest objects,
  lint (doorways, keys per dungeon, big key, glove for heavy rocks, switch-revealed chests); dungeon preview.
- `tests/test_dungeon.gd` (62 checks), `tools/capture_dungeon.gd`.

### Changed
- Scrolling works for any group of areas (the overworld, or one dungeon); captions skip room-to-room moves.
- `GameState` 3.0: key pools, dungeon items, visited areas (saved). `give_item` only auto-equips Y-items.
- 314 checks in 6 suites, all passing.

## [6.0.0] - 2026-10-15 — Phase 5: Items I

### Added
- Y-items on the item button (K / gamepad West): **lantern** (a flame in front that lights torches; 2 magic),
  **boomerang** (flies up to 6 tiles straight or diagonal, stuns enemies, fetches pickups, one at a time),
  **bow** (arrows for 4 damage that stick in walls), **bombs** (1.6 s fuse, blast hurts enemies and Joe, cuts
  bushes, breaks cracked rocks; two at a time). New `src/items/`: `ItemDB` (catalogue, wares), `ItemUse`,
  `Boomerang`, `Arrow`, `Bomb`.
- The item-get sequence: Joe holds the item over his head, fanfare, its text; chests, gifts and pickups all use it.
- World objects: `Chest` (opens from below; can be hidden until every torch of its area burns), `Torch`,
  `CrackedRock` (bombable), `KeyBlock` (spends a small key), `ShopItem` (Boni's wares with prices), heart pieces
  lying in the world. Opened/broken/taken things are remembered as GameState flags.
- Content: the lantern in Joe's house chest; Janga hands over the boomerang on the second talk (dialogue `gift`);
  a small key in an East Lake chest opens a key block on the South Road, guarding the bow; two torches in North
  Meadow reveal a chest with a piece of heart; a cracked rock in West Woods hides another; one lies by East Lake;
  Boni sells bombs (5 for 20), arrows (10 for 15) and one piece of heart (100).
- Heart pieces (four make a container) and heart containers (+1 heart, full refill).
- Dialogue boxes can end in a choice menu (BUY / NO).
- HUD bomb and arrow counters (once owned); the item menu shows counts and the heart-piece quarters.
- `GameState`: bombs, arrows, heart pieces; `add_ammo`, `use_ammo`, `ammo_full`, `add_heart_piece`; saved.
- Generators: `tools/gen_items.py` (icons, world sprites, explosion and flame effects); `gen_sfx.py` adds
  item_get, heart_piece, chest_open, boomerang, arrow_shot, arrow_hit, bomb_place, explode, unlock, lantern,
  shop_buy, error (37 effects). `gen_areas.py`: `OBJECTS` and `WARES` tables, glyphs `C L k l h`, lint for item
  kinds, hidden chests without torches, keys vs key blocks, reachability (key blocks and cracked rocks count as
  openable), wares on tables.
- `tests/test_items.gd` (67 checks), `tools/capture_items.gd`.

### Changed
- Enemies hit by a `stun` HitBox (the boomerang) freeze for 2 s instead of taking damage.
- `Juice` reads a second effects manifest (`vfx_items.json`); `Pickup` gains permanent kinds (heart piece,
  heart container, small key) and the `pickup` group; `HurtBox.recheck()` does nothing while monitoring is off.
- 252 checks in 5 suites, all passing.

## [5.0.0] - 2026-10-15 — Phase 4: HUD, menus, saves, dialogue

### Added
- Title screen (new main scene): "THE VILLAGE" logo over a slow pan across El Pueblo; CONTINUE (when a save
  exists), NEW GAME, QUIT.
- Full ALttP-style HUD: magic meter, equipped-item box, gem counter, small-key counter (hidden at zero),
  "- LIFE -" with up to 20 hearts in two rows; area-name captions when Joe enters an area.
- Dialogue: `DialogueBox` (word-wrapped pages typed out with a blip, speaker name plate, "more" arrow, box at the
  top when Joe is low on the screen; pauses the world). Text lives in `assets/data/dialogue.json`, read by
  `DialogueData` (first-meeting lines set a story flag; later talks use other lines).
- Villagers (`Npc`): Tato, Boni (behind her new shop counter, talked to across it), Janga, and Marta and Pico in
  El Pueblo; they turn to face Joe. Signs are readable (`SignPost`): two in El Pueblo and one in each other area.
  Joe's interact talks/reads before it lifts.
- Pause menu (Esc / Start: CONTINUE, SAVE GAME, SAVE AND QUIT), item menu (I / left shoulder: 5x2 item grid that
  equips found items, equipment, the three family seals), Game Over screen (red-to-black fade; CONTINUE,
  SAVE AND CONTINUE, SAVE AND QUIT) instead of the automatic respawn.
- Save/load (`SaveGame`, `user://village_save.json`): area + entry point, hearts, gems, magic, keys, items,
  equipped item, seals and story flags.
- `GameState` grows magic, keys, items, equipped item, seals, flags, `snapshot()` / `restore()`.
- Generators: `tools/gen_ui.py` (fonts, HUD pieces, boxes, cursor, slots, seals, equipment icons, logo; glyphs in
  `tools/font_glyphs.py`, shared with Chapel of Dreams), `tools/gen_npcs.py` (5 villagers x 3 facings);
  `gen_sfx.py` adds menu_move, menu_select, menu_back, text_blip, pause, save_done, game_over (25 effects) and
  checks each effect against its own level target.
- `gen_areas.py`: villager and sign tables (`NPCS`, `SIGNS`), the `N` glyph, and lint for both (glyph and list
  agree, text exists in dialogue.json, villager sprite exists, Joe can stand next to each one).
- `tests/test_ui.gd` (61 checks), `tools/capture_ui.gd`.

### Changed
- `World` hosts the dialogue box and the menus, opens Game Over on death, saves at the area's entry point and
  applies a pending save; Joe's facing at each entry is remembered.
- `PixelText` and `MenuList` ported from Chapel of Dreams (PixelText gains `wrap()`); UI colours and CanvasLayer
  order live in `UiTheme`.
- 185 checks in 4 suites, all passing.

## [4.0.0] - 2026-10-15 — Phase 3: the overworld engine

### Added
- `World` (new main scene): areas in one global coordinate system, clamped camera (rooms centred), ALttP screen
  scroll between areas (0.6 s, Joe steps in), fades through house doors and exit mats, enemies respawn on
  re-entry, death respawn at the area entry. The game starts in Joe's house.
- `AreaBuilder`: shared ASCII-to-tiles painter with autotiled paths, water, ledges, cliffs and interior walls,
  multi-cell trees/houses/furniture and TileSet flag layers (`ledge`, `door`, `exit`).
- `tools/gen_areas.py`: El Pueblo, North Meadow, West Woods, East Lake, South Road and four house interiors;
  lint (sizes, glyphs, pieces, ledge landings, edge openings, overlaps, door pairing, reachability, one spawn);
  world and interior preview images. New `docs/LEVEL_DESIGN.md`.
- `tools/terrain_art.py` + `gen_tiles.py` v2: 83-cell atlas (water, ledges, cliffs, fence, sign, two cottages,
  interiors). Joe hops down ledges; new sounds `ledge_hop`, `land`, `door` (18 total).
- `tests/test_world.gd` (30 checks), `tools/capture_world.gd`.

### Changed
- `TestField` now paints through `AreaBuilder` (same glyphs as real areas).
- 122 checks in 3 suites, all passing.

## [3.0.0] - 2026-10-15 — Phase 2: combat core and game feel

### Added
- Spin attack: hold the sword button after a slash, shuffle at half speed with the facing locked, the blade glints
  after 0.8 s, release for a 360 degree spin (4 damage).
- The family shield on every Joe frame; it blocks enemy rocks hitting his front (idle, walking, charging).
- Lift, carry and throw pots and bushes (interact); thrown objects arc 4 tiles, hurt enemies, shatter; a hit makes
  Joe drop what he carries.
- Enemies on a shared `BaseEnemy` (knockback, hit flash, i-frames, hit-stop, death puff, drops): slime, Caver's
  guard (patrol + axis chase), rock-spitter (spits blockable rocks).
- `GameState` (gems, drop table), `Pickup` (recovery heart; green/blue/red gems worth 1/5/20), minimal `Hud`
  (hearts with halves, gem counter), respawn at the field spawn after dying.
- Autoloads `Juice` (shake, hit-stop, one-shot effects) and `Audio` (pooled SFX), ported and trimmed from Chapel.
- Generators: `tools/gen_enemies.py`, `tools/gen_props.py` (pot, pickups, HUD hearts/digits, poof/spark/glint/shards),
  `tools/gen_sfx.py` (15 chiptune effects); `gen_joe.py` v2 adds the shield and charge/spin/lift/carry/throw strips.
- `tests/test_combat.gd` (56 checks); `tools/capture_field.gd` v2 captures charge, spin, carry, throw and enemies.

### Changed
- Physics layer 8 renamed `Cuttable` -> `Props` (bushes and pots); `HitBox.blockable`.
- Meadow layout now has pots, three slimes, two guards and two spitters.
- 92 checks in 2 suites, all passing.

## [2.0.0] - 2026-10-15 — Rebuild on the Chapel of Dreams architecture, Phases 0 and 1

The game is now the first, ALttP-inspired chapter of The Village trilogy (prequel to
*Chapel of Dreams*). Owner decisions: rebuild in this repo on Chapel's base, 384×216 render,
Light/Dark mirror worlds.

### Changed
- Godot 4.7.2 project rewritten (`project.godot`): 384×216 viewport, gl_compatibility, top-down
  input map with an SNES-style gamepad layout, physics layer 8 `Cuttable`.
- Docs moved into `docs/` (`GDD.md` rewritten for the trilogy, `ARCHITECTURE.md`, `LORE.md`,
  `TODO.md`) and the full documentation set created; new `docs/ROADMAP.md` (phases 0–15).

### Removed
- The 2026 prototype code (`scenes/`, `scripts/`, `autoloads/`, `Tools/gen_sprites.py`) and its
  sprites — superseded; still available in git history up to `cec47ca`.

### Added
- `tools/palette.py` (Light + Dark World master palette), `tools/sprite_lib.py` (from Chapel).
- `tools/gen_joe.py`: generated top-down Joe — idle, walk, sword slash and hurt in three facings,
  shadow, animation manifest with the slash hit window.
- `tools/gen_tiles.py`: Light World tile atlas (grass, flowers, rock, 2×2 tree, nine-slice path)
  with a solidity manifest, plus bush and leaf-burst sprites.
- Ported from Chapel: `HitBox`, `HurtBox`, `HealthComponent`, `StateMachine`, `SpriteStrips`,
  `HitFlash` + flash shader.
- `Player`: instant 8-way walking, ALttP facing rule, corner nudge, sword slash with buffered
  chains, hurt knockback and blinking invincibility; `PlayerTuning` holds every number.
- `Bush` (solid until cut, leaf burst) and `TestField` (ASCII-layout meadow, runtime TileSet).
- `tests/test_player.gd` (36 checks, all passing) and `tools/capture_field.gd` (screenshots).

## [Unreleased — prototype era, superseded by 2.0.0]

### Added
- `LORE.md` — the original, richer narrative concept (protagonist Joe,
  antagonist Caver, four dimensions) recovered from 2024 coursework,
  preserved as dormant future-vision material
- `assets/branding/` — `thevillage.png/.ico` icon and splash art from the
  2024 Unreal Engine 5 prototype
- `assets/reference/joe/` — Joe's character sheet and 8-frame pixel sprite
  reference art from the 2024 character design coursework
- `assets/audio/` — music and SFX clips from the 2024 Unreal Engine 5
  prototype (⚠️ licenses not yet verified — do not ship before confirming,
  see `technical_memory/technical_memory.ipynb`)
- `technical_memory/technical_memory.ipynb` — running technical decision log

### Changed
- `README.md`, `TODO.md`, `ARCHITECTURE.md`, `GDD.md` — reconciled against
  the actual codebase and rewritten where stale (see
  `technical_memory/technical_memory.ipynb` for the TODO.md vs CLAUDE.md
  phase-completion discrepancy this resolved)

---

## [1.0.0] — 2026-09-07

Documentation overhaul: recovered and documented the project's full
pre-repo history (2024 UVM coursework → Unreal Engine 5 prototype → this
Godot reboot), reconciled the docs against the actual codebase, and
established a permanent technical memory log. First release considered
fully and accurately documented.

---

## [0.5.2] — 2026-07-28

### Added
- `.claude/settings.local.json` — local Claude Code permissions

## [0.5.1] — 2026-07-08

### Security
- Patched `.gitignore` / `.assetignore` against secret exposure

## [0.5.0] — 2026-06-23

### Changed
- Full codebase and docs translation pass from Spanish to English
- Renamed `Sala1_Tutorial.tscn` → `Room1_Tutorial.tscn` and
  `Sala2_Desafio.tscn` → `Room2_Challenge.tscn` for naming consistency

## [0.4.0] — 2026-06-03

### Added
- `autoloads/PauseMenu.gd` — pause menu (ESC toggles PLAYING↔PAUSED)
- `scenes/ui/MainMenu.gd` / `.tscn` — title screen (Play/Quit)
- `scenes/items/HeartPickup.gd` / `.tscn` — collectible heart, drop chance
  configured in `Constants.gd`

### Changed
- `scenes/enemies/Slime.gd` / `.tscn` — heart drop on death
- `scenes/player/Player.gd` — movement tuning
- `scenes/world/Room.gd` — adjustments to support new menus

## [0.3.1] — 2026-06-02

### Changed
- `project.godot` — minor correction

## [0.3.0] — 2026-06-02

### Added
- `scenes/ui/GameOver.gd` / `.tscn` — Game Over screen
- `scenes/world/Door.gd` / `.tscn` — room-to-room transition trigger
- `scenes/world/Room.gd` — base room script (floor generation, camera lock,
  spawn handling)
- `scenes/world/rooms/Sala1_Tutorial.tscn`, `Sala2_Desafio.tscn` — first two
  rooms (renamed to English in `[0.5.0]`)

### Changed
- `autoloads/GameManager.gd` — persists `player_health` between rooms
- `autoloads/SceneManager.gd` — fade + room change via `go_to_room()`
- `ARCHITECTURE.md`, `CLAUDE.md`, `GDD.md`, `README.md` — updated for the
  new room system

## [0.2.0] — 2026-06-01

### Added
- `addons/godot_mcp/` — Godot MCP plugin, enables Claude Code / editor
  integration
- `CLAUDE.md` — project reference doc for AI-assisted development

### Changed
- Corrected basic player/enemy mechanics
- `autoloads/EventBus.gd`, `InputHandler.gd`, `SceneManager.gd` — signal and
  input handling fixes
- `scenes/world/World.gd` — world generation adjustments

## [0.1.0] — 2026-05-26

### Added
- Initial project scaffold: `project.godot`, folder structure,
  `README.md`, `GDD.md`, `ARCHITECTURE.md`, `TODO.md`
- `autoloads/EventBus.gd`, `GameManager.gd`, `SceneManager.gd`,
  `InputHandler.gd` — core singletons
- `scripts/combat/HealthComponent.gd`, `HitBox.gd`, `HurtBox.gd` —
  layer-based damage system
- `scripts/components/StateMachine.gd`, `PixelCamera.gd`,
  `PlaceholderSprite.gd`
- `scripts/data/Constants.gd` — single source of configurable values
- `scenes/player/Player.gd` / `.tscn` — 8-direction movement, sword attack,
  iFrames
- `scenes/enemies/BaseEnemy.gd`, `Slime.gd` / `.tscn` — patrol/chase AI
- `scenes/ui/HealthUI.gd` / `.tscn` — reactive heart HUD
- `scenes/world/World.gd` / `.tscn` — root scene, tilemap generation
- `assets/sprites/` — `tileset_forest.png`, `slime.png`, `sword.png`,
  `bush.png` (real sprites, wired from day one)
- `Tools/gen_sprites.py` — placeholder sprite generation script

## [0.0.1] — 2026-05-25

### Added
- Initial repository with `.gitignore` for Godot 4
