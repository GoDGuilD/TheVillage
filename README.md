<!--
File: README.md
Description: Project overview, status, and getting-started guide for The Village.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-05-26
Last edit date: 2026-10-15
Version: 3.0.0
-->

# The Village

**Version 2.0.0** (project-wide; see `CHANGELOG.md`)

A top-down action-adventure in the style of *The Legend of Zelda: A Link to the Past*, built with Godot 4.7.2.
It is the **first game (prequel) of The Village trilogy**; game 2 is *The Village — Chapel of Dreams*
(a Castlevania: SotN-style metroidvania). Joe comes home to El Pueblo and fights the curse of its ruler, the
vampire-sorcerer Caver, across a Light World and its Dark World mirror.

## Status
Rebuilt on 2026-10-15 on Chapel of Dreams' architecture (Phase 0) and **Phase 1 is done**: Joe walks in 8
directions with ALttP facing rules and corner nudging, swings his sword, cuts bushes and takes hits, in a
two-by-two-screen meadow. 36 automated checks pass. Plan: `docs/ROADMAP.md`. Design: `docs/GDD.md`.

## Run it
1. Open `F:\Software\Godot\Godot_v4.7.2-stable_win64.exe` → Import → this folder → F5.
2. Controls: WASD/arrows to move, J or Space to slash (gamepad: D-pad/stick + A).

## Develop
- Regenerate art: `python -I tools/gen_joe.py` and `python -I tools/gen_tiles.py`, then
  `Godot_v4.7.2-stable_win64_console.exe --headless --path . --import`.
- Tests: `Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . -s tests/test_player.gd`.
- More: `docs/DEVELOPMENT.md`, `docs/TESTING.md`, `docs/ARCHITECTURE.md`.

## Project history
2024 UVM coursework (narrative, character and level design) → an Unreal Engine 5 prototype (Nov–Dec 2024) →
a small Godot prototype (May–Sep 2026, two rooms and slimes) → this rebuild (Oct 2026). The recovered story
lives in `docs/LORE.md`.

Author: Jose-Jorge HERNANDEZ — Parlee Conseiller, Inc.
