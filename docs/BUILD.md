<!--
File: BUILD.md
Description: How to build the game.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-21
Version: 1.1.0
-->

# Build

No build step is needed to play from the editor (F5). Generated art must exist first: `python -I tools/gen_joe.py` and `python -I tools/gen_tiles.py` (their output is committed, so a fresh clone already has it).

When exporting, include the non-resource files the game reads at run time: `localization/*.json`,
`assets/data/*.json`, `src/world/areas/*.json`, the sprite manifests and `assets/audio/sfx_trim.json` (export filter
`*.json`). Windows exports arrive with the release phase (an `export_presets.cfg` like Chapel of Dreams'); until then use Project > Export in the editor with the Windows Desktop template for Godot 4.7.2.
