<!--
File: BUGS.md
Description: Log of every gotcha met, internal or external.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-15
Version: 1.2.1
-->

# Bugs and gotchas

- [Internal] **Tools folder became a file** - Symptom: `tools/palette.py` could not be written (ENOENT). Root cause: Windows paths are case-insensitive; `mkdir tools` was a no-op while the old `Tools/` existed, the old folder was then deleted, and `cp sprite_lib.py tools/` created a *file* named `tools`. Fix: recreated the folder. File: `tools/`.
- [External] **Input press seen one frame late in tests** - Symptom: state still `idle` one frame after `Input.action_press("attack")`. Root cause: Godot flushes action presses into `is_action_just_pressed` on the next physics frame. Workaround: tests wait 2 frames. File: `tests/test_player.gd`.
- [Internal] **Method named `_set` in TestField** - Symptom: would override `Object._set` (property setter virtual). Fix: renamed to `_put_tile`. File: `src/world/TestField.gd`.
- [Internal] **Leaf burst invisible against grass** - Symptom: cut bushes seemed to vanish. Root cause: green leaves with no outline on green grass. Fix: outlined leaf frames + a test that the burst plays. File: `tools/gen_tiles.py`.
- [External] **A new `class_name` hangs the headless suites until `--import`** - Symptom: after adding `AreaBuilder`, the test run never finished (no output, no exit). Root cause: Godot's global class cache is only refreshed by an import/editor pass; scripts naming the new class fail to compile and the `-s` script waits forever. Workaround: run `--headless --path . --import` after adding a `class_name`, and wrap test runs in `timeout`. File: `tests/*`.
- [Internal] **Grass lip across roads at area edges** - Symptom: a thin grass line across the road exactly where two areas meet (seen mid-scroll). Root cause: the nine-slice autotiler treated cells outside the area as "not road". Fix: off-area neighbours count as the same terrain (`AreaBuilder._differs`, and the preview renderer). File: `src/world/AreaBuilder.gd`, `tools/gen_areas.py`.
- [External] **`round()` breaks typed variables** - Symptom: every suite failed to compile with "The variable type is being inferred from a Variant value" at `Hud.gd:171`. Root cause: in Godot 4 the global `round()` returns a Variant, and this project treats inference warnings as errors. Fix: use `roundf()` (or `Vector2.round()`) wherever the result feeds a `:=` variable. File: `src/ui/Hud.gd`, `DialogueBox.gd`, `TitleScreen.gd`.
- [External] **A test naming an autoload-using class fails to compile** - Symptom: `test_ui.gd` failed with "Identifier not found: Audio" in `PauseMenu.gd`, which cascaded into a half-built World (no pause menu, no fade) and 13 failures. Root cause: in `-s` mode the test script is compiled before autoloads are registered, so any class it names statically (`PauseMenu.ITEM_SAVE`) must compile without them. Fix: read the constant through the instance (`world.pause_menu.ITEM_SAVE`). File: `tests/test_ui.gd`.
- [Internal] **Villager lint accepted Joe standing two tiles away** - Symptom: a villager boxed in by rocks still passed the lint (found by a deliberate mutation). Root cause: the counter rule (talk from two tiles away) was applied to every villager in every direction, so a reachable cell beyond a wall counted. Fix: only villagers marked `across` get the two-tile reach, and only along their facing. File: `tools/gen_areas.py`.
