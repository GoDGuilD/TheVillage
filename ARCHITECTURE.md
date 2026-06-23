# Technical Architecture — The Village

Reference document for design decisions. Updated whenever a new pattern is introduced or an existing one changes.

---

## Guiding principles

1. **Low coupling** — systems don't know about each other directly; they communicate via signals.
2. **Composition over inheritance** — reusable logic lives in child nodes, not long base classes.
3. **One responsibility per script** — each `.gd` does one thing and does it well.
4. **Single source of truth** — numeric values live in `Constants.gd`, never scattered around.
5. **No monolithic code** — if a script exceeds ~150 lines, split it.

---

## Folder structure

```
TheVillage/
│
├── autoloads/              ← root-level singletons, immediate visibility
│   ├── EventBus.gd
│   ├── GameManager.gd
│   ├── SceneManager.gd
│   └── AudioManager.gd    (Phase 3)
│
├── scenes/
│   ├── world/
│   │   ├── rooms/          ← one .tscn per room (Phase 4)
│   │   │   ├── Room_Forest_01.tscn
│   │   │   └── Room_Forest_02.tscn
│   │   └── World.tscn      ← orchestrator, contains no geometry
│   ├── player/
│   │   └── Player.tscn
│   ├── enemies/
│   │   ├── Slime.tscn
│   │   └── Bat.tscn        (Phase 6)
│   ├── ui/
│   │   ├── HUD.tscn        ← rename HealthUI → HUD (Phase 4)
│   │   └── menus/
│   │       ├── MainMenu.tscn
│   │       └── GameOver.tscn
│   └── shared/             ← reusable scenes (doors, items)
│       ├── Door.tscn
│       ├── HeartDrop.tscn
│       └── Projectile.tscn (Phase 6)
│
├── scripts/
│   ├── combat/
│   │   ├── HitBox.gd
│   │   ├── HurtBox.gd
│   │   └── HealthComponent.gd
│   ├── components/         ← reusable Node scripts
│   │   ├── StateMachine.gd
│   │   ├── KnockbackComponent.gd  (Phase 5)
│   │   └── FlashComponent.gd      (Phase 5)
│   └── data/
│       └── Constants.gd    ← single source of configurable values
│
├── resources/              ← Godot .tres: data without code
│   └── enemies/
│       └── slime_data.tres
│
└── assets/
	├── sprites/
	├── audio/
	└── fonts/
```

---

## Autoloads — responsibilities

| Autoload | Responsibility | Status |
|----------|-----------------|--------|
| `EventBus` | Signal bus. Signals only, zero logic. | ✅ |
| `GameManager` | Global state (enum GameState) + global references | ✅ |
| `SceneManager` | Room transitions with fade | ✅ |
| `AudioManager` | AudioStreamPlayer pool, SFX and music | Phase 3 |
| `SaveManager` | Persistence with FileAccess | Phase 7 |

**Golden rule:** no autoload calls another autoload directly.
If they need to communicate, they do so through `EventBus`.

---

## Damage system: HitBox / HurtBox

Two `Area2D` types with opposite responsibilities:

- **`HitBox`** — area that *deals* damage. Only has `damage: int`. Detects nothing.
- **`HurtBox`** — area that *receives* damage. Monitors HitBoxes and emits `hurt(damage)`.

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

---

## StateMachine — reusable component

`StateMachine.gd` is a child `Node` that automatically discovers its parent's states by naming convention:

```gdscript
func state_idle_enter() -> void:   # called on enter
func state_idle_update(delta) -> void:  # called every frame
func state_idle_exit() -> void:    # called on exit
```

`_fsm.transition_to("walk")` handles the enter/exit/update cycle automatically.
Used in Player and all enemies to eliminate manual `match` statements.

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
BaseEnemy (CharacterBody2D)  ← defines structure and lifecycle
└── Slime extends BaseEnemy  ← overrides _update_idle/_update_chase
└── Bat   extends BaseEnemy  ← overrides with sinusoidal movement
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
| Rooms | `Room_Biome_NN.tscn` | `Room_Forest_01.tscn` |
| Resources | `snake_case.tres` | `slime_data.tres` |

---

## Health signal flow (reference)

```
Player takes a hit
  → HurtBox.hurt(1)
	→ Player._on_hurt(1)
	  → HealthComponent.take_damage(1)
		→ HealthComponent.health_changed(5, 6)
		  → Player._on_health_changed(5, 6)
			→ EventBus.player_health_changed(5, 6)
			  → HUD._on_health_changed(5, 6)
				→ updates hearts on screen
```
