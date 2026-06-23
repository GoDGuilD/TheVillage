# TODO — The Village

> Priority: 🔴 Critical · 🟠 High · 🟡 Medium · 🟢 Low
> Difficulty: ⬛ 1–5 stars

---

## Phase 0 — Foundation ✅

- [x] 🔴 Folder structure and `project.godot`
- [x] 🔴 `EventBus` + `GameManager` (autoloads)
- [x] 🔴 Reusable `HealthComponent`
- [x] 🔴 `HitBox` / `HurtBox` with collision layers
- [x] 🔴 Player: 8-direction movement + keyboard/gamepad
- [x] 🔴 Player: sword attack + iFrames (invincibility)
- [x] 🔴 Player: state machine (IDLE / WALK / ATTACK)
- [x] 🔴 `BaseEnemy` + `Slime` with basic AI (patrol + chase)
- [x] 🔴 `HealthUI` with ColorRect placeholders
- [x] 🔴 `Camera2D` following the player

---

## Phase 1 — Visibility ⬛⬛⬛⬜⬜

> Unblocks everything else. Top priority.

- [x] 🔴 16×16 placeholder sprite for Player (`PlaceholderSprite.gd`, blue 12×14)
- [x] 🔴 12×12 placeholder sprite for Slime (`PlaceholderSprite.gd`, green 10×10)
- [x] 🔴 TileMap with solid-color tileset (`World.gd → _generate_floor()`)
- [ ] 🔴 Verify Player and Slimes are visible at runtime
- [ ] 🟠 Adjust `Camera2D` limits to map size
- [ ] 🟠 Confirm HitBox/HurtBox work (Debug > Visible Collision Shapes)

---

## Phase 2 — Art and integration ⬛⬛⬜⬜⬜

- [ ] 🟠 Import player spritesheet (Kenney.nl or itch.io, 16×16)
- [ ] 🟠 Set up the 12 animations on Player's `AnimatedSprite2D`
  - idle_down / idle_up / idle_left / idle_right
  - walk_down / walk_up / walk_left / walk_right
  - attack_down / attack_up / attack_left / attack_right
- [ ] 🟠 Import Slime spritesheet (idle + walk)
- [ ] 🟠 Import tileset with correct collisions (TileMapLayer)
- [ ] 🟡 Heart sprites to replace ColorRect in the HUD
- [ ] 🟠 Adjust `CollisionShape2D` to the sprites' real size

---

## Phase 3 — Audio ⬛⬛⬜⬜⬜

- [ ] 🟡 Create `AudioManager` autoload (`scripts/autoloads/AudioManager.gd`)
- [ ] 🟠 SFX: sword attack
- [ ] 🟠 SFX: player takes damage
- [ ] 🟡 SFX: Slime death
- [ ] 🟢 SFX: player footsteps (by floor type)
- [ ] 🟡 Looping ambient music (`AudioStreamPlayer`)

---

## Phase 4 — Level design ⬛⬛⬛⬜⬜

- [ ] 🟠 Room 1: full design with obstacles and enemies
- [ ] 🟡 Room 2: different layout, more enemies
- [ ] 🟠 Doors as `Area2D` triggering a transition
- [ ] 🟠 Scene transition system (fade + `change_scene_to_file`)
- [ ] 🟠 Enemy spawns correctly positioned per room

---

## Phase 5 — Extended combat ⬛⬛⬜⬜⬜

- [ ] 🟠 Knockback on taking damage (player and enemy)
- [ ] 🟡 Red flash on sprite when taking damage (`modulate` + tween)
- [ ] 🟡 Heart drop on killing a Slime (configurable probability)
- [ ] 🟡 Collectible heart item that calls `HealthComponent.heal()`
- [ ] 🟢 Slime death effect (particles or scale tween)

---

## Phase 6 — Second enemy ⬛⬛⬛⬜⬜

- [ ] 🟡 `Bat.gd` — extends `BaseEnemy`, flies (no TileMap collision)
- [ ] 🟡 Sinusoidal movement for Bat
- [ ] 🟢 `Archer.gd` — fires `Projectile.tscn` at the player
- [ ] 🟢 `Projectile.gd` — moves in a fixed direction, has a HitBox, destroys itself on impact

---

## Phase 7 — Game systems ⬛⬛⬜⬜⬜

- [ ] 🟠 Game Over screen with Restart button
- [ ] 🟡 Main menu (Play, Quit)
- [ ] 🟢 Persistence with `FileAccess` (furthest room reached)

---

## Phase 8 — Polish ⬛⬛⬜⬜⬜

- [ ] 🟢 Camera shake on taking damage
- [ ] 🟢 Squash & stretch on Slime (scale tween)
- [ ] 🟡 Black fade on room transition
- [ ] 🟢 Circular shadow under player and enemies (semi-transparent `Sprite2D`)
- [ ] 🟢 Animated hearts in the HUD

---

## Backlog — ideas for future versions

- [ ] Second weapon type (bow and arrows)
- [ ] Keys and locked doors system
- [ ] Minimap
- [ ] NPC dialogue using `RichTextLabel`
- [ ] Multi-phase boss
- [ ] Full save system
- [ ] Mobile build with touch controls
