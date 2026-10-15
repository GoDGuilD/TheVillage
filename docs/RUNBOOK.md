<!--
File: RUNBOOK.md
Description: Step-by-step procedures.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-15
Version: 1.2.0
-->

# Runbook

## Regenerate all art
1. `python -I tools/gen_joe.py`, `gen_tiles.py`, `gen_enemies.py`, `gen_props.py`
2. `python -I tools/gen_sfx.py` (must report `0 with problems`), `python -I tools/gen_areas.py` (`0 lint problems`)
3. `F:\Software\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --import`
4. Run the suites.

## Verify a phase
1. Run every suite in `TESTING.md` (0 failed, expected count: 122).
2. Windowed capture: `F:\Software\Godot\Godot_v4.7.2-stable_win64_console.exe --path . -s tools/capture_field.gd`; inspect `tmp/field_*.png`.
3. Update CHANGELOG, ROADMAP status, README version; commit as Jose-Jorge HERNANDEZ.
