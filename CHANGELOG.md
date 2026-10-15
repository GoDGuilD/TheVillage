<!--
File: CHANGELOG.md
Description: Dated record of all relevant changes to The Village, reconstructed from git history and pre-repo project history.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-05-26
Last edit date: 2026-10-15
Version: 3.0.0
-->

# Changelog — The Village

All relevant project changes are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

> **Before this repo existed:** The Village began as a school project at UVM in
> February 2024 — a much larger narrative concept, built up across four
> different courses and finished as a working Unreal Engine 5 prototype in
> December 2024. This repo is a from-scratch reboot in Godot, deliberately
> scoped down to a lean prototype. See `LORE.md` for the original narrative
> and `technical_memory/technical_memory.ipynb` for the full recovered
> timeline and the reasoning behind this changelog's structure.

---

## [2.0.0] - 2026-10-15 — Rebuild on the Chapel of Dreams architecture, Phases 0 and 1

The game is now the first, ALttP-inspired chapter of The Village trilogy (prequel to
*Chapel of Dreams*). Owner decisions: rebuild in this repo on Chapel's base, 384×216 render,
Light/Dark mirror worlds.

### Changed
- Godot 4.7.2 project rewritten (`project.godot`): 384×216 viewport, gl_compatibility, top-down
  input map with an SNES-style gamepad layout, physics layer 8 `Cuttable`.
- Docs moved into `docs/` (`GDD.md` rewritten for the trilogy, `ARCHITECTURE.md`, `LORE.md`,
  `TODO.md`) and the full documentation set created; new `docs/ROADMAP.md` (phases 0–15).

### Removed
- The 2026 prototype code (`scenes/`, `scripts/`, `autoloads/`, `Tools/gen_sprites.py`) and its
  sprites — superseded; still available in git history up to `cec47ca`.

### Added
- `tools/palette.py` (Light + Dark World master palette), `tools/sprite_lib.py` (from Chapel).
- `tools/gen_joe.py`: generated top-down Joe — idle, walk, sword slash and hurt in three facings,
  shadow, animation manifest with the slash hit window.
- `tools/gen_tiles.py`: Light World tile atlas (grass, flowers, rock, 2×2 tree, nine-slice path)
  with a solidity manifest, plus bush and leaf-burst sprites.
- Ported from Chapel: `HitBox`, `HurtBox`, `HealthComponent`, `StateMachine`, `SpriteStrips`,
  `HitFlash` + flash shader.
- `Player`: instant 8-way walking, ALttP facing rule, corner nudge, sword slash with buffered
  chains, hurt knockback and blinking invincibility; `PlayerTuning` holds every number.
- `Bush` (solid until cut, leaf burst) and `TestField` (ASCII-layout meadow, runtime TileSet).
- `tests/test_player.gd` (36 checks, all passing) and `tools/capture_field.gd` (screenshots).

## [Unreleased — prototype era, superseded by 2.0.0]

### Added
- `LORE.md` — the original, richer narrative concept (protagonist Joe,
  antagonist Caver, four dimensions) recovered from 2024 coursework,
  preserved as dormant future-vision material
- `assets/branding/` — `thevillage.png/.ico` icon and splash art from the
  2024 Unreal Engine 5 prototype
- `assets/reference/joe/` — Joe's character sheet and 8-frame pixel sprite
  reference art from the 2024 character design coursework
- `assets/audio/` — music and SFX clips from the 2024 Unreal Engine 5
  prototype (⚠️ licenses not yet verified — do not ship before confirming,
  see `technical_memory/technical_memory.ipynb`)
- `technical_memory/technical_memory.ipynb` — running technical decision log

### Changed
- `README.md`, `TODO.md`, `ARCHITECTURE.md`, `GDD.md` — reconciled against
  the actual codebase and rewritten where stale (see
  `technical_memory/technical_memory.ipynb` for the TODO.md vs CLAUDE.md
  phase-completion discrepancy this resolved)

---

## [1.0.0] — 2026-09-07

Documentation overhaul: recovered and documented the project's full
pre-repo history (2024 UVM coursework → Unreal Engine 5 prototype → this
Godot reboot), reconciled the docs against the actual codebase, and
established a permanent technical memory log. First release considered
fully and accurately documented.

---

## [0.5.2] — 2026-07-28

### Added
- `.claude/settings.local.json` — local Claude Code permissions

## [0.5.1] — 2026-07-08

### Security
- Patched `.gitignore` / `.assetignore` against secret exposure

## [0.5.0] — 2026-06-23

### Changed
- Full codebase and docs translation pass from Spanish to English
- Renamed `Sala1_Tutorial.tscn` → `Room1_Tutorial.tscn` and
  `Sala2_Desafio.tscn` → `Room2_Challenge.tscn` for naming consistency

## [0.4.0] — 2026-06-03

### Added
- `autoloads/PauseMenu.gd` — pause menu (ESC toggles PLAYING↔PAUSED)
- `scenes/ui/MainMenu.gd` / `.tscn` — title screen (Play/Quit)
- `scenes/items/HeartPickup.gd` / `.tscn` — collectible heart, drop chance
  configured in `Constants.gd`

### Changed
- `scenes/enemies/Slime.gd` / `.tscn` — heart drop on death
- `scenes/player/Player.gd` — movement tuning
- `scenes/world/Room.gd` — adjustments to support new menus

## [0.3.1] — 2026-06-02

### Changed
- `project.godot` — minor correction

## [0.3.0] — 2026-06-02

### Added
- `scenes/ui/GameOver.gd` / `.tscn` — Game Over screen
- `scenes/world/Door.gd` / `.tscn` — room-to-room transition trigger
- `scenes/world/Room.gd` — base room script (floor generation, camera lock,
  spawn handling)
- `scenes/world/rooms/Sala1_Tutorial.tscn`, `Sala2_Desafio.tscn` — first two
  rooms (renamed to English in `[0.5.0]`)

### Changed
- `autoloads/GameManager.gd` — persists `player_health` between rooms
- `autoloads/SceneManager.gd` — fade + room change via `go_to_room()`
- `ARCHITECTURE.md`, `CLAUDE.md`, `GDD.md`, `README.md` — updated for the
  new room system

## [0.2.0] — 2026-06-01

### Added
- `addons/godot_mcp/` — Godot MCP plugin, enables Claude Code / editor
  integration
- `CLAUDE.md` — project reference doc for AI-assisted development

### Changed
- Corrected basic player/enemy mechanics
- `autoloads/EventBus.gd`, `InputHandler.gd`, `SceneManager.gd` — signal and
  input handling fixes
- `scenes/world/World.gd` — world generation adjustments

## [0.1.0] — 2026-05-26

### Added
- Initial project scaffold: `project.godot`, folder structure,
  `README.md`, `GDD.md`, `ARCHITECTURE.md`, `TODO.md`
- `autoloads/EventBus.gd`, `GameManager.gd`, `SceneManager.gd`,
  `InputHandler.gd` — core singletons
- `scripts/combat/HealthComponent.gd`, `HitBox.gd`, `HurtBox.gd` —
  layer-based damage system
- `scripts/components/StateMachine.gd`, `PixelCamera.gd`,
  `PlaceholderSprite.gd`
- `scripts/data/Constants.gd` — single source of configurable values
- `scenes/player/Player.gd` / `.tscn` — 8-direction movement, sword attack,
  iFrames
- `scenes/enemies/BaseEnemy.gd`, `Slime.gd` / `.tscn` — patrol/chase AI
- `scenes/ui/HealthUI.gd` / `.tscn` — reactive heart HUD
- `scenes/world/World.gd` / `.tscn` — root scene, tilemap generation
- `assets/sprites/` — `tileset_forest.png`, `slime.png`, `sword.png`,
  `bush.png` (real sprites, wired from day one)
- `Tools/gen_sprites.py` — placeholder sprite generation script

## [0.0.1] — 2026-05-25

### Added
- Initial repository with `.gitignore` for Godot 4
