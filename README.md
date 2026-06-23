# The Village

A top-down action-RPG prototype inspired by *Zelda: A Link to the Past*, built with Godot 4.6 and GDScript.

---

## Description

The Village is a 2D top-down game with real-time combat. The player explores interconnected maps, fights enemies with a sword, and manages their life through a heart system. The short-term goal is a playable prototype with one map, one enemy type, and core mechanics working.

---

## Prototype goals

- [x] 8-direction top-down movement with keyboard and gamepad support
- [x] Decoupled HitBox / HurtBox collision system
- [x] Slime-type enemy with patrol and chase AI
- [x] Health system with a reusable component
- [x] Reactive heart HUD via signal bus
- [ ] Player sprites and animations (idle / walk / attack × 4 dirs)
- [ ] Playable TileMap with collisions
- [ ] Audio: SFX and background music
- [ ] Room transitions
- [ ] Game Over screen / Main menu

---

## Tech stack

| Tool | Version | Role |
|-------------|---------|-----|
| [Godot Engine](https://godotengine.org/) | 4.6 | Game engine |
| GDScript | 2.0 | Scripting language |
| [Cursor AI](https://cursor.sh/) | latest | AI-assisted editor |
| GitHub | — | Version control |

---

## Controls

| Action | Keyboard | Gamepad |
|--------|---------|---------|
| Move | `WASD` / Arrows | Left stick / D-pad |
| Attack | `Space` | South button (A / Cross) |

---

## Architecture

The project applies low-coupling principles through three key patterns:

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
├── scenes/
│   ├── world/          # Root game scene
│   ├── player/         # CharacterBody2D + player scripts
│   ├── enemies/        # BaseEnemy + subclasses (Slime, ...)
│   └── ui/             # HUD and screens
├── scripts/
│   ├── autoloads/      # EventBus, GameManager (singletons)
│   └── combat/         # HealthComponent, HitBox, HurtBox
└── assets/
	├── sprites/        # player/, enemies/, world/
	└── audio/          # sfx/, music/
```

---

## Roadmap

### Phase 0 — Foundation ✅
Folder structure, script architecture, HitBox/HurtBox system, movement logic, Slime AI, health HUD.

### Phase 1 — Visibility (next)
16×16px placeholder sprites for the player and the Slime. Basic TileMap with a color tileset. Camera fitted to the map.

### Phase 2 — Art and integration
Import a real spritesheet (Kenney.nl or itch.io). Configure animations on `AnimatedSprite2D`. Tileset with correctly shaped collisions.

### Phase 3 — Audio
`AudioManager` singleton. SFX for attack, damage, death. Looping ambient music with `AudioStreamPlayer`.

### Phase 4 — Level design
Room 1 (implicit tutorial). Room 2 with additional enemies. Scene transition with fade.

### Phase 5 — Extended combat
Knockback on taking damage. Visual flash with a simple shader. Heart drops on enemy kill. Second enemy type.

### Phase 6 — Game systems
Main menu. Game Over screen. Basic save system (`ConfigFile` or `FileAccess`).

### Phase 7 — Polish
*Juice* tweens (squash & stretch). Death particles. Heart sprites in the HUD. Camera shake on taking damage.

---

## Getting started

1. Open Godot 4.6 → **Import** → select `project.godot`
2. Verify that the `EventBus` and `GameManager` autoloads appear under **Project → Project Settings → Autoload**
3. Open `scenes/world/World.tscn` and press **F5**
4. Enable **Debug → Visible Collision Shapes** to see hitboxes while there are no sprites yet

---

## Recommended free art resources

- **Kenney.nl** — `kenney.nl/assets` — Dungeon Tileset, RPG characters (CC0)
- **itch.io** — filter by `free + top-down + pixel art`
- Target size: **16×16px** per tile and character sprite

---

## License

No license defined yet.
