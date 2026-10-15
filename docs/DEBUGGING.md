<!--
File: DEBUGGING.md
Description: Debugging tips.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-15
Version: 1.0.0
-->

# Debugging

- Run a suite with the console exe to see `PASS`/`FAIL` lines and script errors; a script error can silently skip later checks, so compare the check count.
- Visual problems: run `tools/capture_field.gd` windowed and read `tmp/field_*.png`; generator previews are `tmp/joe_preview.png` and `tmp/tiles_preview.png`.
- Collision shapes: Debug > Visible Collision Shapes in the editor, then F5.
- Joe's state is in `player.fsm.current_state`; facing in `player.facing`.
