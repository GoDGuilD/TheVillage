<!--
File: TESTING.md
Description: How the game is tested.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-15
Version: 1.1.0
-->

# Testing

## Headless suites
```
F:\Software\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . -s tests/test_player.gd
F:\Software\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . -s tests/test_combat.gd
```
Each must end `RESULT: N passed, 0 failed`. Current count: **92 checks** in 2 suites (36 + 56).

- `test_player.gd` builds a walled arena through `TestField.layout` and checks walking, the ALttP facing rules,
  walls, corner nudging, the slash (state, animation, hit window, chains), bushes, hurt knockback and i-frames, and
  the default meadow.
- `test_combat.gd` checks the charge and spin (timing, early release, half-speed shuffle, hits all around), the
  guard (damage, knockback, hit-stop, defeat in 3 slashes, forced gem drop and pickup), hearts, the shield (front
  blocks, back and mid-swing do not), contact damage, lifting/carrying/throwing pots and bushes, a thrown pot killing
  a slime, dropping on a hit, the spitter's rock, the guard's chase, the HUD, death and respawn.

## Rules
- An action pressed with `Input.action_press` is seen on the next physics frame: wait 2 frames before asserting.
- Drive movement with `player._input_override = Vector2(...)`; reset it to `Vector2.ZERO`.
- Reach autoloads at runtime (`root.get_node("GameState")`) and load enemy scripts with `load()`; never name an
  autoload or a class that uses one as a static type in an `-s` script (it compiles before the autoloads exist).
- Set `GameState.drops_enabled = false` for deterministic runs; use `GameState.force_drop` to test a drop.
- Park test enemies (`_park`) so their AI does not wander off; give them `player` only when testing a chase.

## Visual checks
Headless runs cannot render. `F:\Software\Godot\Godot_v4.7.2-stable_win64_console.exe --path . -s tools/capture_field.gd` opens a window and saves
`tmp/field_*.png` (idle, walk, slash, leaves, charge, spin, carry, throw, enemies). Joe's hurt box is switched off
during the capture so patrolling enemies cannot interrupt the scripted moments.
