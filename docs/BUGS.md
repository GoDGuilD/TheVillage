<!--
File: BUGS.md
Description: Log of every gotcha met, internal or external.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-15
Version: 1.1.0
-->

# Bugs and gotchas

- [Internal] **Tools folder became a file** - Symptom: `tools/palette.py` could not be written (ENOENT). Root cause: Windows paths are case-insensitive; `mkdir tools` was a no-op while the old `Tools/` existed, the old folder was then deleted, and `cp sprite_lib.py tools/` created a *file* named `tools`. Fix: recreated the folder. File: `tools/`.
- [External] **Input press seen one frame late in tests** - Symptom: state still `idle` one frame after `Input.action_press("attack")`. Root cause: Godot flushes action presses into `is_action_just_pressed` on the next physics frame. Workaround: tests wait 2 frames. File: `tests/test_player.gd`.
- [Internal] **Method named `_set` in TestField** - Symptom: would override `Object._set` (property setter virtual). Fix: renamed to `_put_tile`. File: `src/world/TestField.gd`.
- [Internal] **Leaf burst invisible against grass** - Symptom: cut bushes seemed to vanish. Root cause: green leaves with no outline on green grass. Fix: outlined leaf frames + a test that the burst plays. File: `tools/gen_tiles.py`.
- [External] **A new `class_name` hangs the headless suites until `--import`** - Symptom: after adding `AreaBuilder`, the test run never finished (no output, no exit). Root cause: Godot's global class cache is only refreshed by an import/editor pass; scripts naming the new class fail to compile and the `-s` script waits forever. Workaround: run `--headless --path . --import` after adding a `class_name`, and wrap test runs in `timeout`. File: `tests/*`.
- [Internal] **Grass lip across roads at area edges** - Symptom: a thin grass line across the road exactly where two areas meet (seen mid-scroll). Root cause: the nine-slice autotiler treated cells outside the area as "not road". Fix: off-area neighbours count as the same terrain (`AreaBuilder._differs`, and the preview renderer). File: `src/world/AreaBuilder.gd`, `tools/gen_areas.py`.
