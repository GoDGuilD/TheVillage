<!--
File: CLAUDE.md
Description: Project-specific guidance for AI-assisted development on The Village (game 1 of the trilogy, ALttP-inspired).
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-06-01
Last edit date: 2026-10-15
Version: 2.3.0
-->

# The Village

Top-down 2D action-adventure inspired by *A Link to the Past* — game 1 (prequel) of The Village trilogy.
Game 2 is `H:\DEV\TheVillage-ChapelOfDreams` (SotN-style): **the architecture, tooling and testing method are
ported from it** — read its CLAUDE.md for the long list of Godot gotchas already paid for.

- Godot 4.7.2 at `F:\Software\Godot` (use `Godot_v4.7.2-stable_win64_console.exe`).
- Design truth: `docs/GDD.md`; phases: `docs/ROADMAP.md`; code map: `docs/ARCHITECTURE.md`.
- Render 384×216 (owner's choice, same as Chapel), integer scale, nearest filter, 16 px tiles, feet-origin actors.
- World shape (owner's choice): ALttP **Light/Dark mirror worlds**; the four lore dimensions are Dark World regions.
- The 2026 prototype (EventBus/GameManager/SceneManager…) was retired on 2026-10-15; it is in git history only.
- All code, comments and docs in English. Company in headers: Parlee Conseiller, Inc.

## Working rules
- Art is **generated** by `tools/gen_*.py` from `tools/palette.py` (`python -I tools/gen_joe.py`, `gen_tiles.py`).
  Never hand-edit generated PNGs. After generating PNGs run `Godot_console --headless --path . --import`.
- Feel constants live only in `src/player/PlayerTuning.gd`.
- Tests: `Godot_console --headless --fixed-fps 60 --path . -s tests/test_player.gd` must end `0 failed`.
  An action pressed with `Input.action_press` is seen on the *next* physics frame — wait 2 frames before checking.
  Drive movement in tests with `player._input_override = Vector2(...)`.
- Screenshots need a windowed run: `Godot_console --path . -s tools/capture_field.gd` (writes `tmp/field_*.png`).
- Never name a method `_set`/`_get` in a Node script (they are Object virtuals) — `TestField` uses `_put_tile`.
- The filesystem is case-insensitive: the old `Tools/` and the new `tools/` are the same folder.
- `TestField.layout` can be replaced before the node enters the tree (tests build custom arenas this way).
- A HitBox hurts only while `monitorable`; toggle it with `HitBox.set_active()`.
- Write long Python/patch scripts to files; long inline heredocs can break the Bash tool.
- Two suites now (`test_player.gd` 36, `test_combat.gd` 56). In `-s` tests reach autoloads with
  `root.get_node("GameState")` and `load()` enemy scripts - never use autoload-using classes as static types.
  Set `GameState.drops_enabled = false`; force drops with `GameState.force_drop`.
- Sounds only through `Audio.sfx(name)` (files from `tools/gen_sfx.py`), effects only through
  `Juice.play_fx(name, pos, parent)` (`assets/sprites/vfx/vfx_manifest.json`). Hit-stop calls `freeze()` on actors.
- Enemies extend `BaseEnemy` (pack + stats in `_init()`, AI in `_think()`); hit them in tests via the sword or
  `_on_hurt`, never `health.take_damage` (skips flash/knockback/death).
- Contracts: liftable (`can_lift()`, `lift() -> {kind, texture}`, group `liftable`), pickup (`collect(kind)`),
  blockable projectile (`HitBox.blockable` + a `deflect()` on its parent). Physics layer 8 is `Props` (bushes, pots).
- Windowed captures switch Joe's hurt box off so patrolling enemies cannot spoil a scripted shot.
- Phase 3: the main scene is `World` (areas from `src/world/areas/*.json`, written by `tools/gen_areas.py` - must
  print `0 lint problems`; never edit the JSON). Glyphs live in `AreaBuilder.gd` and `docs/LEVEL_DESIGN.md`.
  Three suites now (122 checks). After adding a `class_name` run `--import`, and always wrap Godot runs in `timeout`
  (a compile failure hangs a headless `-s` run). World tests move Joe with `world._enter(area, world.cell_feet(...))`.
- Terrain flags (`ledge`, `door`, `exit`) are TileSet custom data read with `AreaBuilder.flag_at`; nine-slices treat
  off-area cells as the same terrain (seamless edges).
- Phase 4: the main scene is `src/ui/TitleScreen.tscn`; the World hosts `DialogueBox`, `PauseMenu`, `ItemMenu`,
  `GameOver` (all pause the tree; their layers are `PROCESS_MODE_ALWAYS`). Four suites now (185 checks; `test_ui.gd`
  61). Villagers/signs come from the `NPCS`/`SIGNS` tables in `gen_areas.py`; their text is
  `assets/data/dialogue.json` (the lint checks keys). UI colours/layers only via `UiTheme`.
- Never name an autoload-using class statically in a `-s` test (`PauseMenu.ITEM_SAVE` breaks compilation): read
  constants through the instance. Use `roundf()`, not `round()`, for typed variables (warnings are errors).
- Menus read `_unhandled_input`: tests drive them with `Input.parse_input_event` or `confirm()`/`advance()`; UI
  tests and captures set `SaveGame.path` to a throw-away file so the player's save is never touched.
