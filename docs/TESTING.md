<!--
File: TESTING.md
Description: How the game is tested.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-15
Version: 1.4.0
-->

# Testing

## Headless suites
```
F:\Software\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . -s tests/test_player.gd
F:\Software\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . -s tests/test_combat.gd
F:\Software\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . -s tests/test_world.gd
F:\Software\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . -s tests/test_ui.gd
F:\Software\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . -s tests/test_items.gd
```
Each must end `RESULT: N passed, 0 failed`. Current count: **252 checks** in 5 suites (36 + 56 + 32 + 61 + 67).
Run them with a `timeout` wrapper: a script that fails to compile (e.g. a new `class_name` before `--import`)
makes Godot wait forever instead of failing.

- `test_player.gd`: walking, facing rules, walls, corner nudge, slash, bushes, hurt and i-frames, default meadow.
- `test_combat.gd`: charge and spin, guard/slime/spitter, hit-stop, drops and pickups, shield, lift/carry/throw,
  HUD, death and respawn.
- `test_world.gd`: area data (9 areas, 4 doors), the start in Joe's house, exit mat and door warps, screen scrolls
  north/west/east/south and back, camera clamping and centring, ledge hop (and no climbing back), water, enemy
  respawn on re-entry, death -> Game Over -> continue at the area entry.
- `test_ui.gd`: word wrap, dialogue data and flags, HUD (hearts, magic, keys, gems, captions), talking to Tato
  (pause, facing, typing, first and later lines, closing does not re-open), the crossroads sign, Boni across her
  counter, lift still works, box placement, pause menu + saving, item menu + equipping, no menu during a
  conversation, save -> new World from the save, version mismatch, title screen with and without a save.
- `test_items.gd`: item data, ammo and heart pieces, the lantern chest and item-get pose, chests only from below,
  torches revealing the meadow chest, key -> key block -> bow, arrows (kill, stick, no ammo), Janga's gift,
  boomerang (one at a time, stun, return, fetch), the shop (no gems, NO, buy, full bag, one-time ware), bombs
  (count, two at a time, blast, cracked rock, heart piece behind it, hurts Joe), heart containers, HUD/menu
  read-outs, save -> load keeps items, chests and blocks.

## Level lint
`python -I tools/gen_areas.py` must print `0 lint problems` (it checks sizes, glyphs, multi-cell pieces, ledge
landings, edge openings, door pairing, reachability and the single spawn).

## Rules
- An action pressed with `Input.action_press` is seen on the next physics frame: wait 2 frames before asserting.
- Drive movement with `player._input_override = Vector2(...)`; reset it to `Vector2.ZERO`.
- Reach autoloads at runtime (`root.get_node("GameState")`) and `load()` scripts that use them.
- `GameState.drops_enabled = false` for deterministic runs; `GameState.force_drop` to test a drop.
- World tests jump between areas with `world._enter(area, world.cell_feet(area, [x, y]), facing)`.
- Menus read `_unhandled_input`: drive them with `Input.parse_input_event(InputEventAction)` (see `_press` in
  `test_ui.gd`) or call `menu.confirm()` / `dialogue.advance()` directly.
- Never name an autoload-using class statically in a test (`PauseMenu.ITEM_SAVE` breaks compilation in `-s`
  mode); read constants through the instance (`world.pause_menu.ITEM_SAVE`).
- After an item-get Joe faces down (ALttP pose): face him again before the next interact in a test. Item use
  holds Joe in `use` for 0.2 s - wait ~15 frames between two item presses.
- Read autoloads in tests through nodes (`root.get_node("Audio")`), never by name.
- UI tests point `SaveGame.path` at `user://test_village_save.json` and delete it afterwards.

## Visual checks
Headless runs cannot render. Windowed captures: `tools/capture_field.gd` (combat moments in the test meadow,
`tmp/field_*.png`) and `tools/capture_world.gd` (house, village, a scroll mid-slide, every neighbouring area, the
ledge hop; `tmp/world_*.png`) and `tools/capture_ui.gd` (title, HUD + caption, Tato, a sign, Boni, pause menu,
item menu, Game Over; `tmp/ui_*.png`) and `tools/capture_items.gd` (lantern item-get, torches, boomerang,
arrow, bomb fuse and blast, Boni's counter, key nook, item menu; `tmp/items_*.png`). Joe's hurt box is switched off during captures.
