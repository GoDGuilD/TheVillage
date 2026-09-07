<!--
File: TODO.md
Description: Development backlog for The Village, organized on the same phase numbering as CLAUDE.md.
Author: Jose-Jorge HERNANDEZ
Company: Parlee Conseiller, Inc.
Date: 2026-05-26
Last edit date: 2026-09-07
Version: 2.0.0
-->

# TODO — The Village

> Priority: 🔴 Critical · 🟠 High · 🟡 Medium · 🟢 Low
> Difficulty: ⬛ 1–5 stars
>
> Phase numbers match `CLAUDE.md`'s "Development phases" table — the two
> documents share one scheme now so they can't drift apart the way this file
> previously did (it used to track an older 0–8 scheme that never got
> updated after Phases 1–6 actually shipped; see
> `technical_memory/technical_memory.ipynb` for that reconciliation).

---

## Phase 1 — Core prototype ✅

- [x] 🔴 Folder structure and `project.godot`
- [x] 🔴 `EventBus` + `GameManager` (autoloads)
- [x] 🔴 Reusable `HealthComponent`
- [x] 🔴 `HitBox` / `HurtBox` with collision layers
- [x] 🔴 Player: 8-direction movement + keyboard/gamepad (`InputHandler`)
- [x] 🔴 Player: sword attack + iFrames (invincibility)
- [x] 🔴 Player: state machine (IDLE / WALK / ATTACK / KNOCKBACK)
- [x] 🔴 `BaseEnemy` + `Slime` with basic AI (patrol + chase)
- [x] 🔴 `HealthUI` reactive heart HUD via `EventBus`
- [x] 🔴 `PixelCamera` following the player, pixel-perfect
- [x] 🔴 Game Over screen

## Phase 2 — Room system ✅

- [x] 🔴 `Room.gd` base script — floor generation, camera lock, spawn handling
- [x] 🔴 `Door.tscn` — `Area2D` trigger, `target_scene` + `spawn_id`
- [x] 🔴 Room 1 (`Room1_Tutorial.tscn`) ↔ Room 2 (`Room2_Challenge.tscn`)
- [x] 🔴 `player_health` persists between rooms (`GameManager`)

## Phase 3 — Items ✅

- [x] 🟠 `HeartPickup.tscn` / `.gd`
- [x] 🟠 30% drop chance from Slime death (`Constants.HEART_DROP_CHANCE`)

## Phase 4 — Main menu ✅

- [x] 🟠 `MainMenu.tscn` — title screen, Play/Quit

## Phase 5 — Pause menu ✅

- [x] 🟠 `PauseMenu.gd` autoload — ESC toggles PLAYING↔PAUSED
- [x] 🟡 "EXIT TO MENU" unpauses before `go_to_room()`

## Phase 6 — Real sprites ✅

- [x] 🟠 `tileset_forest.png` wired into `World.gd` tilemap generation
- [x] 🟠 `slime.png` wired into `Slime.tscn`
- [x] 🟠 `sword.png` wired into `Player.tscn` / `Player.gd`
- [ ] 🟢 `bush.png` — imported but not placed in any room yet
- [ ] 🟡 Player body sprite — still `PlaceholderSprite.gd` (no `player.png`
      provided); `assets/reference/joe/` now has 8 pixel-art frames from the
      2024 character design coursework that could seed a real one

---

## Phase 7 — Audio ⬛⬛⬜⬜⬜ (not started)

`assets/audio/` now has candidate clips recovered from the 2024 Unreal
Engine 5 prototype (bg music, button click, forest ambience, footsteps,
jump SFX) — **verify licensing before shipping any of them** (see
`technical_memory/technical_memory.ipynb`).

- [ ] 🟡 `AudioManager` autoload (`AudioStreamPlayer` pool for SFX + music)
- [ ] 🟠 SFX: sword attack
- [ ] 🟠 SFX: player takes damage
- [ ] 🟡 SFX: Slime death
- [ ] 🟢 SFX: player footsteps (by floor type)
- [ ] 🟡 Looping ambient music per room

## Phase 8 — Second enemy & extended combat ⬛⬛⬛⬜⬜ (not started)

- [ ] 🟡 `Bat.gd` — extends `BaseEnemy`, flies (no TileMap collision),
      sinusoidal movement
- [ ] 🟢 `Archer.gd` — fires `Projectile.tscn` at the player
- [ ] 🟢 `Projectile.gd` — moves in a fixed direction, has a HitBox, destroys
      itself on impact
- [ ] 🟡 Enemy knockback on taking damage (player already has a KNOCKBACK
      state; enemies don't yet)
- [ ] 🟡 Red flash on sprite when taking damage (`modulate` + tween)
- [ ] 🟢 Slime death effect (particles or scale tween)

## Phase 9 — Save system & polish ⬛⬛⬜⬜⬜ (not started)

- [ ] 🟢 Persistence with `FileAccess` (furthest room reached)
- [ ] 🟢 Camera shake on taking damage
- [ ] 🟢 Squash & stretch on Slime (scale tween)
- [ ] 🟡 Black fade on room transition (`SceneManager` already fades —
      confirm it reads as a full black frame, not just a cut)
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
- [ ] Revisit `LORE.md` — the original narrative (Joe/Caver/Tato/Boni/Janga,
      four dimensions) if the project ever grows beyond prototype scope
