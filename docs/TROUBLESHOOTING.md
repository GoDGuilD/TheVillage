<!--
File: TROUBLESHOOTING.md
Description: Common problems and fixes.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-15
Version: 1.0.0
-->

# Troubleshooting

| Symptom | Fix |
|---|---|
| `Failed loading resource` for a PNG after regenerating art | Run `Godot_console --headless --path . --import` |
| A test says `idle` right after pressing attack | The press is seen next physics frame; wait 2 frames |
| Screenshots are black or missing | Capture scripts need a windowed run (no `--headless`) |
| `ObjectDB instances were leaked` at exit | Harmless warning at teardown |
| Python import errors in `tools/` | Run from the project root with `python -I tools/<script>.py`; Pillow must be installed |
