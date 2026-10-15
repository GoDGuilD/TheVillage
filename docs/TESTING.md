<!--
File: TESTING.md
Description: How the game is tested.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-15
Version: 1.0.0
-->

# Testing

## Headless suites
```
F:\Software\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . -s tests/test_player.gd
```
Must end `RESULT: N passed, 0 failed`. Current count: **36 checks** in 1 suite.

`test_player.gd` builds a walled arena through `TestField.layout` and checks: idle start, full-speed walking without acceleration, mirrored left walking, normalised diagonals, the ALttP facing rules, walls, corner nudging (and no nudge dead-centre), the slash (state, animation, hit window, no movement mid-slash), chained slashes, bushes blocking and being cut (with a leaf burst), hurt knockback and i-frames, and the default meadow.

## Rules
- An action pressed with `Input.action_press` is seen on the next physics frame: wait 2 frames before asserting.
- Drive movement with `player._input_override = Vector2(...)`; reset it to `Vector2.ZERO`.
- Keep test variables holding the player untyped (pattern from Chapel of Dreams).

## Visual checks
Headless runs cannot render. `F:\Software\Godot\Godot_v4.7.2-stable_win64_console.exe --path . -s tools/capture_field.gd` opens a window, walks Joe, slashes a bush and saves `tmp/field_*.png`.
