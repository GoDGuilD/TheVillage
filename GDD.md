# Game Design Document — The Village

Living document. Updated with every relevant design decision.

---

## Concept

| Field | Value |
|-------|-------|
| Genre | Top-down 2D action-RPG |
| Inspiration | Zelda: A Link to the Past, Hyper Light Drifter |
| Perspective | Top-down |
| Scope | Prototype / playable demo |
| Target platform | PC (Windows/Linux/Mac) |
| Engine | Godot 4.6 |

### Premise
The player explores a small village and its surroundings, fights the creatures threatening it, and seeks to solve the mystery behind its origin.

---

## Design pillars

1. **Rewarded exploration** — the map invites you off the obvious path.
2. **Readable combat** — the player always knows why they died.
3. **Satisfying progression** — even the prototype should feel like progress.

---

## Player

### Base stats (prototype)
| Stat | Value | Notes |
|------|-------|-------|
| Max health | 6 hearts | Represented as half-hearts |
| Speed | 80 px/s | Top-down, 8 directions |
| Sword damage | 1 heart | No variations for now |
| Attack duration | 0.3 s | `AttackTimer` duration |
| iFrames after damage | 1.0 s | `InvincibilityTimer` duration |

### Controls
| Action | Keyboard | Gamepad |
|--------|---------|---------|
| Move | WASD / Arrows | Left stick / D-pad |
| Attack | Space | South button (A / Cross) |
| *Future: interact* | E | East button (B / Circle) |
| *Future: inventory* | I / Tab | West button (X / Square) |

### Required animations
12 animations = 3 states × 4 directions

```
idle_down   walk_down   attack_down
idle_up     walk_up     attack_up
idle_left   walk_left   attack_left
idle_right  walk_right  attack_right
```

---

## Enemies

### Slime (Phase 0)
| Stat | Value |
|------|-------|
| Health | 2 hits |
| Speed | 35 px/s |
| Contact damage | 1 heart |
| Detection radius | 80 px |
| Chase radius | 120 px (1.5× detection) |
| Idle behavior | Random patrol (direction change every 1.5–3 s) |

### Bat (Phase 6 — planned)
| Stat | Value |
|------|-------|
| Health | 1 hit |
| Speed | 55 px/s |
| Contact damage | 1 heart |
| Behavior | Sinusoidal movement, ignores TileMap collisions |

### Archer (Phase 6 — planned)
| Stat | Value |
|------|-------|
| Health | 3 hits |
| Projectile damage | 1 heart |
| Firing range | 100 px |
| Firing cooldown | 2 s |

---

## Room structure

```
[Room 1 — Implicit tutorial]
  • 2–3 Slimes
  • No complex obstacles
  • North door → Room 2

[Room 2 — First challenge]
  • 4–5 Slimes + 1 Bat (phase 6)
  • Obstacles requiring detours
  • South door → Room 1
```

### Room design (principles)
- Each room fits on **one screen** (approx. 320×180 px at 1× scale)
- Enemies appear in positions that teach their mechanics
- Exits are visible from the entry point

---

## Item economy (prototype)

| Item | Source | Effect |
|------|--------|--------|
| Half heart | Slime drop (30% chance) | `HealthComponent.heal(1)` |
| *Future: key* | Chest | Opens locked doors |

---

## Aesthetics

### Reference palette (Zelda: A Link to the Past)
- Warm tones for outdoors (green, brown, beige)
- Cool tones for interiors (stone gray, dark blue)
- High contrast on enemies for readability

### Target tile size
**16×16 px** per tile. Render scale: 2× or 3× for modern screens.
In Godot: `Window > Stretch Mode = canvas_items`, `Aspect = keep`.

### Audio (style references)
- Music: SNES-style chiptune with memorable melodies
- SFX: short, distinct from each other, not fatiguing on loop

---

## Prototype success metrics

The prototype is considered complete when:

- [x] A new player can move the character in under 5 seconds
- [x] A new player understands how to attack without reading instructions
- [x] It's possible to die and know why — Game Over screen
- [x] There are at least 2 connected rooms — Sala1_Tutorial ↔ Sala2_Desafio (Phase 2)
- [x] The game doesn't crash during a 5-minute session

---

## Out of scope (prototype)

The following elements are explicitly excluded to keep focus:

- Story and dialogue
- Complex inventory system
- More than 2 enemy types
- Save progress between sessions
- Dynamic lighting effects
- Multiplayer
