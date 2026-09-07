<!--
File: ARCHITECTURE.md
Description: Technical architecture reference for The Village — current structure and design patterns, with planned/future items clearly marked as not yet built.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-05-26
Last edit date: 2026-09-07
Version: 2.0.0
-->

# Technical Architecture — The Village

Reference document for design decisions. Updated whenever a new pattern is
introduced or an existing one changes.

> This version separates **current** (what's actually on disk today) from
> **planned** (aspirational, not built yet) — a previous revision blurred the
> two, which contributed to `TODO.md` going stale. See
> `technical_memory/technical_memory.ipynb` for that history.

---

## Guiding principles

1. **Low coupling** — systems don't know about each other directly; they communicate via signals.
2. **Composition over inheritance** — reusable logic lives in child nodes, not long base classes.
3. **One responsibility per script** — each `.gd` does one thing and does it well.
4. **Single source of truth** — numeric values live in `Constants.gd`, never scattered around.
5. **No monolithic code** — if a script exceeds ~150 lines, split it.

---

## Folder structure (current)

```
TheVillage/
│
├── autoloads/               ← root-level singletons, immediate visibility
│   ├── EventBus.gd
│   ├── GameManager.gd
│   ├── SceneManager.gd
│   ├── InputHandler.gd
│   └── PauseMenu.gd
│
├── scenes/
│   ├── world/
│   │   ├── rooms/
│   │   │   ├── Room1_Tutorial.tscn
│   │   │   └── Room2_Challenge.tscn
│   │   ├── World.gd / .tscn   ← orchestrator
│   │   ├── Room.gd            ← base room script
│   │   └── Door.gd / .tscn    ← room-to-room transition trigger
│   ├── player/
│   │   └── Player.gd / .tscn
│   ├── enemies/
│   │   ├── BaseEnemy.gd
│   │   └── Slime.gd / .tscn
│   ├── items/
│   │   └── HeartPickup.gd / .tscn
│   └── ui/
│       ├── HealthUI.gd / .tscn
│       ├── GameOver.gd / .tscn
│       └── MainMenu.gd / .tscn
│
├── scripts/
│   ├── combat/
│   │   ├── HitBox.gd
│   │   ├── HurtBox.gd
│   │   └── HealthComponent.gd
│   ├── components/
│   │   ├── StateMachine.gd
│   │   ├── PixelCamera.gd
│   │   └── PlaceholderSprite.gd
│   └── data/
│       └── Constants.gd       ← single source of configurable values
│
├── resources/                 ← Godot .tres: data without code (empty so far)
│   └── enemies/
│
├── assets/
│   ├── sprites/
│   │   ├── player/             → sword.png (wired)
│   │   ├── enemies/            → slime.png (wired)
│   │   └── world/              → tileset_forest.png (wired), bush.png (imported, not placed)
│   ├── audio/                  → clips recovered from the 2024 UE5 prototype,
│   │                              not yet wired, licenses unverified (Phase 7)
│   ├── branding/                → thevillage.png/.ico icon + splash art,
│   │                              recovered from the 2024 UE5 prototype
│   └── reference/joe/           → character design reference art (not
│                                   imported as game assets — reference only)
│
├── addons/godot_mcp/           ← Godot MCP plugin, editor/Claude Code integration
├── Tools/
│   └── gen_sprites.py
├── technical_memory/
│   └── technical_memory.ipynb
└── LORE.md                     ← original, richer narrative (dormant, out of
                                   current scope — see GDD.md's "Out of scope")
```

## Folder structure (planned — not built yet)

These items appear in earlier drafts of this document as if already in
place; they are not. Listed here so the intent isn't lost, without
misrepresenting current state:

```
autoloads/
  └── AudioManager.gd          (Phase 7)
  └── SaveManager.gd           (Phase 9)

scenes/
  ├── enemies/
  │   └── Bat.tscn             (Phase 8)
  ├── shared/                  ← reusable scenes; Door.tscn currently lives
  │   │                          in scenes/world/ instead — revisit if a
  │   │                          second reusable "shared" scene shows up
  │   └── Projectile.tscn      (Phase 8)
  └── ui/
      └── HUD.tscn             ← proposed rename of HealthUI.tscn, not done

resources/enemies/
  └── slime_data.tres          ← Slime's stats are still hardcoded in
                                   Slime.gd / Constants.gd, not data-driven yet
```

---

## Autoloads — responsibilities

| Autoload | Responsibility | Status |
|----------|-----------------|--------|
| `EventBus` | Signal bus. Signals only, zero logic. | ✅ |
| `GameManager` | Global state (`GameState` enum), entity registry, persists `player_health` between rooms | ✅ |
| `SceneManager` | Room transitions with fade — `go_to_room(path, spawn_id)` | ✅ |
| `InputHandler` | Input abstraction. Never use `Input` directly. Persists between scenes. | ✅ |
| `PauseMenu` | Pause menu. ESC toggles PLAYING↔PAUSED. | ✅ |
| `AudioManager` | `AudioStreamPlayer` pool, SFX and music | Phase 7 |
| `SaveManager` | Persistence with `FileAccess` | Phase 9 |

**Golden rule:** no autoload calls another autoload directly.
If they need to communicate, they do so through `EventBus`.

---

## Damage system: HitBox / HurtBox

Two `Area2D` types with opposite responsibilities:

- **`HitBox`** — area that *deals* damage. Only has `damage: int`. Detects nothing.
- **`HurtBox`** — area that *receives* damage. Monitors HitBoxes and emits `hurt(damage, source_position)`.

### 2D collision layers

```
Layer 1  (bitmask  1)  — World:         TileMapLayer and static bodies
Layer 2  (bitmask  2)  — Player:        Player's CharacterBody2D
Layer 3  (bitmask  4)  — Enemies:       Enemies' CharacterBody2D
Layer 4  (bitmask  8)  — PlayerHitBox:  Player's sword
Layer 5  (bitmask 16)  — EnemyHitBox:   Enemy contact
Layer 6  (bitmask 32)  — PlayerHurtBox: Player's damage zone
Layer 7  (bitmask 64)  — EnemyHurtBox:  Enemies' damage zone
```

Rule: the `HurtBox` has `monitoring=true` and its mask points to the layer of the `HitBox` it should detect.

⚠️ **Gotcha:** the sword `HitBox` requires toggling BOTH `monitoring` AND
`monitorable` — `monitoring` alone causes phantom damage to nearby enemies
(the `monitorable=true` flag alone activates enemy HurtBoxes). See
`CLAUDE.md`'s "Known gotchas" table for this and other fixed bugs.

---

## StateMachine — reusable component

`StateMachine.gd` is a child `Node` that automatically discovers its parent's states by naming convention:

```gdscript
func state_idle_enter() -> void:   # called on enter
func state_idle_update(delta) -> void:  # called every frame
func state_idle_exit() -> void:    # called on exit
```

`_fsm.transition_to("walk")` handles the enter/exit/update cycle automatically.
Used in Player (IDLE / WALK / ATTACK / KNOCKBACK) and all enemies to eliminate manual `match` statements.

---

## Signal strategy — two levels

```
LEVEL 1 — Local signals (same scene)
────────────────────────────────────────
HurtBox.hurt          → entity._on_hurt()
HealthComponent.died  → entity._on_died()
Timer.timeout         → entity._on_attack_finished()

LEVEL 2 — EventBus (across different scenes)
────────────────────────────────────────
Player      → EventBus.player_health_changed → HUD
Player      → EventBus.player_died           → GameManager → GameOver
Slime       → EventBus.enemy_died            → GameManager
SceneManager → EventBus.room_entered         → HUD

Rule: use a local signal if the emitter knows exactly who's listening
	   and both live in the same root scene.
	   Use EventBus if the emitter doesn't know (or care) who's listening.
```

---

## HealthComponent

Child `Node` that encapsulates health. Emits signals, doesn't touch the parent directly.

```
entity/
└── HealthComponent   ← max_health configurable via @export
```

Signals: `health_changed(current, max)` and `died()`.
Compatible with any node — player, enemy, barrel, boss.

---

## BaseEnemy / Enemy inheritance

```
BaseEnemy (CharacterBody2D)  ← defines structure and lifecycle (IDLE / CHASE / DEAD)
└── Slime extends BaseEnemy  ← overrides _update_idle/_update_chase
└── Bat   extends BaseEnemy  ← Phase 8, not built — sinusoidal movement, ignores TileMap collisions
```

Adding an enemy = new `.gd` + `.tscn`. No changes to existing files.

---

## GameManager — game states

```
MENU ──play──→ PLAYING ──pause──→ PAUSED
					  │                  │
					  │←──────resume─────┘
					  │
				  player_died
					  │
				  GAME_OVER ──restart──→ PLAYING
```

---

## Naming conventions

| Element | Convention | Example |
|----------|------------|---------|
| Classes / scenes | PascalCase | `Player`, `HealthComponent` |
| Private variables | `_snake_case` | `_state`, `_facing` |
| Exported variables | `snake_case` | `move_speed`, `max_health` |
| Constants | `SCREAMING_SNAKE` | `PLAYER_SPEED`, `SWORD_DAMAGE` |
| Signals | snake_case, past tense | `player_died`, `health_changed` |
| Public methods | `verb_noun()` | `take_damage()`, `register_player()` |
| Private methods | `_verb_noun()` | `_handle_movement()` |
| Signal callbacks | `_on_source_event()` | `_on_hurt()`, `_on_attack_finished()` |
| Rooms | `RoomN_Name.tscn` | `Room1_Tutorial.tscn`, `Room2_Challenge.tscn` |
| Resources | `snake_case.tres` | `slime_data.tres` (planned) |

---

## Health signal flow (reference)

```
Player takes a hit
  → HurtBox.hurt(1, source_position)
	→ Player._on_hurt(1)
	  → HealthComponent.take_damage(1)
		→ HealthComponent.health_changed(5, 6)
		  → Player._on_health_changed(5, 6)
			→ EventBus.player_health_changed(5, 6)
			  → HUD._on_health_changed(5, 6)
				→ updates hearts on screen
```
