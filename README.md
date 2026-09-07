<!--
File: README.md
Description: Project overview, status, and getting-started guide for The Village.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-05-26
Last edit date: 2026-09-07
Version: 2.0.0
-->

# The Village

**Version 1.0.0** (project-wide; see `CHANGELOG.md`)

A top-down action-RPG prototype inspired by *Zelda: A Link to the Past*, built with Godot 4.6 and GDScript.

---

## Description

The Village is a 2D top-down game with real-time combat. The player explores interconnected rooms, fights enemies with a sword, and manages their life through a heart system.

This prototype is a deliberately small, from-scratch reboot — see **Project history** below for where the name and the wider concept actually came from, and `GDD.md` for what's explicitly out of scope for now.

---

## Current status

All of the prototype's core phases are done (see `CLAUDE.md`'s "Development phases" table and `TODO.md` for the detailed, up-to-date backlog):

- [x] 8-direction top-down movement with keyboard and gamepad support
- [x] Decoupled HitBox / HurtBox collision system
- [x] Slime-type enemy with patrol and chase AI
- [x] Health system with a reusable component
- [x] Reactive heart HUD via signal bus
- [x] Real sprites wired (tileset, slime, sword)
- [x] Two connected rooms with doors and health persistence
- [x] Heart pickups (30% drop from Slime)
- [x] Main menu and Pause menu
- [x] Game Over screen
- [ ] Player sprites and animations (body is still a placeholder — see
      `assets/reference/joe/` for pixel-art reference recovered from the
      2024 coursework)
- [ ] Audio: SFX and background music (candidate clips in `assets/audio/`,
      licenses not yet verified — see `TODO.md` Phase 7)
- [ ] Second enemy type, extended combat polish (`TODO.md` Phase 8)
- [ ] Save system (`TODO.md` Phase 9)

---

## Tech stack

| Tool | Version | Role |
|-------------|---------|-----|
| [Godot Engine](https://godotengine.org/) | 4.6.3 | Game engine |
| GDScript | 2.0 | Scripting language |
| [Claude Code](https://claude.com/claude-code) | — | AI-assisted development, via the `godot_mcp` addon |
| GitHub | — | Version control |

## Running the project

Open Godot 4.6.3 → Open this project → F5 to run. The `addons/godot_mcp`
plugin should be enabled in Project Settings for Claude Code integration.

---

## Controls

| Action | Keyboard | Gamepad |
|--------|---------|---------|
| Move | `WASD` / Arrows | Left stick / D-pad |
| Attack | `Space` | South button (A / Cross) |
| Pause | `Esc` | Start |

---

## Architecture

See `ARCHITECTURE.md` for the full technical reference. In short, the
project applies low-coupling principles through three key patterns:

**Signal Bus (`EventBus`)** — A singleton that relays global events. No system talks directly to another; they emit signals that any listener can hear without knowing the emitter.

**Composition via nodes (`HealthComponent`, `HitBox`, `HurtBox`)** — Health and damage logic lives in reusable child nodes, not monolithic scripts. Any entity (player, enemy, barrel) can have health simply by adding a `HealthComponent`.

**Lightweight inheritance for enemies (`BaseEnemy → Slime`)** — The base class defines the state machine. Subclasses only override `_update_idle()` and `_update_chase()`.

### 2D collision layers

| Layer | Name | Bitmask |
|-------|--------|---------|
| 1 | World (TileMap) | 1 |
| 2 | Player | 2 |
| 3 | Enemies | 4 |
| 4 | PlayerHitBox (sword) | 8 |
| 5 | EnemyHitBox (contact) | 16 |
| 6 | PlayerHurtBox | 32 |
| 7 | EnemyHurtBox | 64 |

---

## Project structure

```
TheVillage/
├── autoloads/           # EventBus, GameManager, SceneManager, InputHandler, PauseMenu
├── scenes/
│   ├── world/            # Room.gd, Door.gd/.tscn, World.gd/.tscn, world/rooms/
│   ├── player/           # CharacterBody2D + player scripts
│   ├── enemies/          # BaseEnemy + subclasses (Slime, ...)
│   ├── items/            # HeartPickup
│   └── ui/                # MainMenu, HealthUI, GameOver
├── scripts/
│   ├── combat/            # HitBox, HurtBox, HealthComponent
│   ├── components/        # StateMachine, PixelCamera, PlaceholderSprite
│   └── data/               # Constants
├── resources/            # Godot .tres data (empty so far)
├── assets/
│   ├── sprites/           # player/, enemies/, world/
│   ├── audio/             # music/SFX candidates — licenses not yet verified
│   ├── branding/          # icon + splash art recovered from the 2024 UE5 prototype
│   └── reference/joe/     # character design reference art (not wired in-game)
├── addons/godot_mcp/     # Claude Code / editor integration
├── Tools/                 # gen_sprites.py
├── technical_memory/      # technical_memory.ipynb — running decision log
└── LORE.md               # original, richer narrative (dormant, out of current scope)
```

---

## Project history

"The Village" name and concept predate this repo by two years. It started
in February 2024 as a school project at UVM and was built up across four
different courses — narrative design, character design, scene/level
design, and finally a full playable prototype in Unreal Engine 5 (finished
December 2024). That original concept had a full story (protagonist Joe,
the vampire-sorcerer Caver, and four distinct dimensions) — see `LORE.md`
for the recovered narrative, kept as dormant reference material.

This repo picks the name back up in May 2026 as a from-scratch Godot
rebuild, deliberately scoped down to a lean, story-free prototype (see
`GDD.md`'s "Out of scope" section). No code or assets carried over from the
UE5 project directly; a handful of art and audio files were recovered from
the school archive and brought in as reference/candidate material (see
`assets/branding/`, `assets/reference/joe/`, `assets/audio/`).

Full timeline: `technical_memory/technical_memory.ipynb`.

---

## Recommended free art resources

- **Kenney.nl** — `kenney.nl/assets` — Dungeon Tileset, RPG characters (CC0)
- **itch.io** — filter by `free + top-down + pixel art`
- Target size: **16×16px** per tile and character sprite

---

## License

No license defined yet.
