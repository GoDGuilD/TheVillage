<!--
File: BUILD.md
Description: How to build the game.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-22
Version: 1.2.0
-->

# Build

No build step is needed to play from the editor (F5). Generated art must exist first: `python -I tools/gen_joe.py` and `python -I tools/gen_tiles.py` (their output is committed, so a fresh clone already has it).

When exporting, include the non-resource files the game reads at run time: `localization/*.json`,
`assets/data/*.json`, `src/world/areas/*.json`, the sprite manifests and `assets/audio/sfx_trim.json` (export filter
`*.json`). `export_presets.cfg` has a Windows Desktop preset that does this:

```
F:\Software\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release "Windows Desktop"
```

It writes one EXE (PCK embedded, custom icon) to `H:\PROJECTS\Exported Games\The Village.exe`. Smoke test it with
`"The Village.exe" --headless --quit-after 600` (exit code 0, no errors). Keep `addons/` in the export: the enabled
`godot_mcp` editor plugin adds a runtime autoload at export time (inert without a debugger), and leaving the addon out
makes the EXE log a failed autoload. Godot warns that the icon lacks some sizes; the EXE still gets the icon.
