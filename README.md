<!--
File: README.md
Description: Project overview, status, and getting-started guide for The Village.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-05-26
Last edit date: 2026-10-16
Version: 5.3.0
-->

# The Village

**Version 7.0.0** (project-wide; see `CHANGELOG.md`)

A top-down action-adventure in the style of *The Legend of Zelda: A Link to the Past*, built with Godot 4.7.2.
It is the **first game (prequel) of The Village trilogy**; game 2 is *The Village — Chapel of Dreams*
(a Castlevania: SotN-style metroidvania). Joe comes home to El Pueblo and fights the curse of its ruler, the
vampire-sorcerer Caver, across a Light World and its Dark World mirror.

## Status
Rebuilt on 2026-10-15 on Chapel of Dreams' architecture. **Phases 0–6 are done**: Joe walks in 8 directions with
ALttP facing rules and corner nudging, slashes, charges a spin attack, blocks rocks with his shield, lifts and throws
pots and bushes, and fights slimes, Caver's guards and rock-spitters that drop hearts and gems, in a
hearts/gems HUD and generated sound effects. The game starts in Joe's house in El Pueblo; four neighbouring areas
scroll into each other ALttP-style, houses can be entered, and ledges can be hopped down. A title screen, the full
ALttP HUD, villagers to talk to (Tato, Boni, Janga and two neighbours), readable signs, pause and item menus,
Game Over and save/load are in. The first items work: lantern, boomerang, bow and bombs, chests, small keys and
key blocks, torches, cracked rocks, heart pieces and Boni's shop. The first dungeon, the Moss Shrine, is
playable end to end: locked and big-key doors, shutters, switches, a push block, pits, map and compass, the
Power Glove, the Grand Slime and the first family seal. 314 automated checks pass.
Plan: `docs/ROADMAP.md`. Design: `docs/GDD.md`.

## Run it
1. Open `F:\Software\Godot\Godot_v4.7.2-stable_win64.exe` → Import → this folder → F5.
2. Controls: WASD/arrows move; J or Space slashes (hold to charge, release to spin); E or Enter talks, reads,
   lifts, throws and opens chests; K uses the equipped item; Tab shows the map; Esc pauses (save here); I opens the item menu
   (gamepad: D-pad/stick, A = sword, B = talk/lift, Y = item, Start = pause, left shoulder = items).

## Develop
- Regenerate art and sound: `python -I tools/gen_joe.py`, `gen_tiles.py`, `gen_enemies.py`, `gen_props.py`,
  `gen_ui.py`, `gen_npcs.py`, `gen_items.py`, `gen_dungeon.py`, `gen_sfx.py`, `gen_areas.py` (the world; must print `0 lint problems`), then
  `Godot_v4.7.2-stable_win64_console.exe --headless --path . --import`.
- Tests: `Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . -s tests/test_player.gd`
  and the same with `tests/test_combat.gd`, `tests/test_world.gd`, `tests/test_ui.gd`, `tests/test_items.gd` and `tests/test_dungeon.gd`.
- More: `docs/DEVELOPMENT.md`, `docs/TESTING.md`, `docs/ARCHITECTURE.md`.

## Project history
2024 UVM coursework (narrative, character and level design) → an Unreal Engine 5 prototype (Nov–Dec 2024) →
a small Godot prototype (May–Sep 2026, two rooms and slimes) → this rebuild (Oct 2026). The recovered story
lives in `docs/LORE.md`.

Author: Jose-Jorge HERNANDEZ — Parlee Conseiller, Inc.
