<!--
File: TESTING.md
Description: How the game is tested.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-21
Version: 1.8.0
-->

# Testing

## Headless suites
```
F:\Software\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . -s tests/test_player.gd
F:\Software\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . -s tests/test_combat.gd
F:\Software\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . -s tests/test_world.gd
F:\Software\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . -s tests/test_ui.gd
F:\Software\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . -s tests/test_items.gd
F:\Software\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . -s tests/test_dungeon.gd
F:\Software\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . -s tests/test_act1.gd
F:\Software\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . -s tests/test_dark.gd
F:\Software\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . -s tests/test_umbra.gd
```
Each must end `RESULT: N passed, 0 failed`. Current count: **441 checks** in 9 suites (36 + 56 + 32 + 61 + 67 + 62 + 54 + 28 + 45).
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
- `test_dungeon.gd`: dungeon data, shrine door and stairs, room scroll and the 40 px push, pits, per-dungeon keys,
  locked door, clearing the west room's shutter (and it staying open), the push block onto the heavy switch,
  switch shutter, map screen with map and compass, big key / big chest / big door, the Grand Slime (minions,
  no stun, defeat, door, heart container, seal, way out, empty room afterwards), heavy rocks with the glove,
  save -> load keeps dungeon progress.
- `test_act1.gd`: dungeon table and rooms, Act 1 texts, magic jars, the road south (glove, scroll into the South
  Fields), dash (needs boots, charge, speed, bonk, dash kill), rubble, fire rod (magic, torches from afar, no magic),
  bats over pits, Iron Ram (armour, charge, daze, damage, seal 2), Frost Wraith (resists, shards, fire, seal 3),
  seal gate (two seals / three seals / stays open / into the keep), Caver's shade (sword resisted, orbs, three
  batted orbs), the ending (last words, end card, save in the Dark World, title screen).
- `test_dark.gd`: twins and groups, dark atlas, tint, tougher enemies, Tato's echo, Dark World scroll and map,
  no rifts before Act 1 ends, the Act 2 opening (once), the Moon Mirror (Light World refusal, warp to the same
  spot, portal arming and return, bounce off a solid spot), the island's piece of heart, a dream rift.

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
- Hit enemies with a given element in tests by setting `hurt_box.last_hit` to a HitBox with that element
  before `_on_hurt` (see `_hit` in `test_act1.gd`). Never name boss or AreaBuilder classes statically in a test
  (`is IronRam`, `AreaBuilder.flag_at`): compare `get_script().get_global_name()` or `load()` the script.
- A rebuilt room frees its nodes: fetch doors/switches/blocks again after `_enter`.
- Read autoloads in tests through nodes (`root.get_node("Audio")`), never by name.
- UI tests point `SaveGame.path` at `user://test_village_save.json` and delete it afterwards.

## Visual checks
Headless runs cannot render. Windowed captures: `tools/capture_field.gd` (combat moments in the test meadow,
`tmp/field_*.png`) and `tools/capture_world.gd` (house, village, a scroll mid-slide, every neighbouring area, the
ledge hop; `tmp/world_*.png`) and `tools/capture_ui.gd` (title, HUD + caption, Tato, a sign, Boni, pause menu,
item menu, Game Over; `tmp/ui_*.png`) and `tools/capture_items.gd` (lantern item-get, torches, boomerang,
arrow, bomb fuse and blast, Boni's counter, key nook, item menu; `tmp/items_*.png`) and `tools/capture_dungeon.gd`
(shrine, rooms, shutter, block, map, glove, boss, reward; `tmp/dungeon_*.png`) and `tools/capture_act1.gd` (fields,
vault fence, dash, fireball, the three bosses, end card; `tmp/act1_*.png`) and `tools/capture_dark.gd` (Hollow
Pueblo, the dry pond, the mirror island, a rift, the Dark World map; `tmp/dark_*.png`). Joe's hurt box is switched off during captures.
