<!--
File: DEVELOPMENT.md
Description: Dev setup, ignore files, conventions.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-10-15
Last edit date: 2026-10-15
Version: 1.0.0
-->

# Development

- Engine: `F:\Software\Godot\Godot_v4.7.2-stable_win64.exe` (editor) / `..._console.exe` (scripts, tests).
- Python 3 + Pillow for the art tools: `python -I tools/gen_joe.py`, `python -I tools/gen_tiles.py`.
- Tests: see `TESTING.md`.

## Ignore files
- `.gitignore` - what git never tracks: `.godot/` (engine cache), `build/` (exports), `backups/`, `tmp/*` (scratch, previews), env files, Python caches, OS/editor cruft. Every entry carries a comment in the file.
- `.assetignore` - what asset tooling skips: editor source art (`*.pxo`, `*.aseprite`), `assets/reference/`, the uncleared 2024 audio masters, `tmp/`. Documented intent for the `tools/` scripts' authors; Godot itself does not read it.

## Day-to-day workflow
1. Change a generator in `tools/` or a script in `src/`.
2. Regenerate art, then `Godot --headless --path . --import` (needed after new PNGs or a new `class_name`).
3. Run the headless suites; compare the number of checks, not just `0 failed`.
4. Look at it: `Godot_console --path . -s tools/capture_field.gd` writes `tmp/field_*.png`.
5. Update `../CHANGELOG.md`, stale docs, `BUGS.md`, the technical memory notebook; bump headers and the README version.

## Folder layout
`src/` game code, `tools/` generators and capture scripts, `tests/` suites, `assets/` art (generated) and recovered 2024 material, `docs/` documentation, `technical_memory/` decision log, `tmp/` scratch (git-ignored). The other bootstrap folders (`config/`, `database/`, `infrastructure/`, `integrations/`, `public/`, `samples/`, `scripts/`, `security/`, `templates/`, `licenses/`, `localization/`, `artifacts/`) are placeholders until a phase needs them.
