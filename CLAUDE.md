# The Village — Godot Project

Top-down 2D action-RPG, inspired by Zelda: A Link to the Past. Engine: Godot 4.6.3.

## Running the project
Open `D:\SOFTWARE\GoDot\Godot_v4.6.3-stable_win64.exe` → Open this project → F5 to run.
MCP plugin (`addons/godot_mcp`) must be enabled for Claude Code integration.

## Architecture

### Autoloads (load order matters)
| Autoload | Responsibility |
|---|---|
| `EventBus` | Signal bus. Signals only, zero logic. |
| `GameManager` | Global state (MENU/PLAYING/PAUSED/GAME_OVER), entity registry, persists `player_health` between rooms. |
| `SceneManager` | Fade + room change. Use `go_to_room(path, spawn_id)`. CanvasLayer layer=128. |
| `InputHandler` | Input abstraction. Never use `Input` directly. Persists between scenes — Player._ready() always resets `controller_enabled = true`. |
| `PauseMenu` | Pause menu. CanvasLayer layer=125, PROCESS_MODE_ALWAYS. Listens to `InputHandler.pause_pressed`. Only active in PLAYING/PAUSED state. |

### Key systems
- **Combat**: `HitBox` (Area2D, layer) + `HurtBox` (Area2D, mask + signal `hurt`)
  - ⚠️ Sword HitBox requires toggling BOTH `monitoring` AND `monitorable` — `monitoring` alone causes phantom damage to nearby enemies
- **Player FSM**: states defined as `state_X_enter/update/exit()` methods, driven by `StateMachine.gd`
- **Enemies**: extend `BaseEnemy` → override `_update_idle()` and `_update_chase()`
- **Health**: `HealthComponent` node (composable), emits `health_changed` / `died`
- **Room system**: `Room.gd` base script — generates floor, walls, locks camera to viewport, handles spawn via `EventBus.room_entered`
- **Doors**: `Door.tscn` (Area2D trigger) — exports `target_scene` + `spawn_id`, detects Player body (mask=2)
- **Game Over**: `GameOver.tscn` instantiated by `HealthUI` and added to root on death. Freed with `queue_free()` on retry.
- **Main Menu**: `MainMenu.tscn` is the main_scene. CanvasLayer layer=0. Resets pause and MENU state in `_ready()`.
- **Pause Menu**: autoload `PauseMenu.gd`. ESC toggles PLAYING↔PAUSED. "EXIT TO MENU" unpauses before `go_to_room()` — SceneManager tweens don't advance while `paused=true`.
- **Sprites**: `PlaceholderSprite.inject()` auto-skips if SpriteFrames already have frames — real sprites in Slime.tscn and sword in Player.tscn/Player.gd. Player body stays placeholder (no player.png provided).

### Known gotchas (bugs already fixed — don't repeat)
| Problem | Cause | Solution |
|---|---|---|
| Slimes die when touching the player | `monitorable=true` on sword HitBox activates enemy HurtBox | Toggle `monitorable` together with `monitoring` |
| GameOver didn't appear | Connected to `player_died` but the signal had already been emitted | Call `_on_jugador_muerto()` directly in `_ready()` |
| Health bar empty on retry | `save_player_health()` saved 0 (player dead) over the -1 | Don't save if `current_health <= 0` |
| GameOver persists after retry | Added to root, not destroyed on scene change | `queue_free()` before `go_to_room()` |
| Input blocked after retry | `InputHandler.controller_enabled=false` persists between scenes | `Player._ready()` always resets it to `true` |

### Collision layers (project.godot)
| Layer | Name | Bitmask value |
|---|---|---|
| 1 | World | 1 |
| 2 | Player | 2 |
| 3 | Enemies | 4 |
| 4 | PlayerHitBox | 8 |
| 5 | EnemyHitBox | 16 |
| 6 | PlayerHurtBox | 32 |
| 7 | EnemyHurtBox | 64 |

### Display
- Viewport: 320×180 px, stretch=canvas_items, scale=integer
- Texture filter: nearest (pixel-perfect)
- Camera: `PixelCamera.gd` on a Camera2D child of Player (rounds position to integers)
- Camera limits: Room.gd fixes them to the viewport for a single-screen room (no scroll)

### Important scene paths
- Main scene: `res://scenes/ui/MainMenu.tscn`
- `Constants.SCENE_ROOM1` / `Constants.SCENE_ROOM2` / `Constants.SCENE_MAIN_MENU` / `Constants.SCENE_HEART_PICKUP` — use these constants, never hardcoded strings
- `Constants.HEART_DROP_CHANCE = 0.30` — probability of a HeartPickup drop when a Slime dies

## Development philosophy
- **Only implement what's requested.** No preemptive systems.
- **Comments in English.** Variable/method names in English (GDScript convention).
- **Prototype is complete.** All 6 phases done. Real sprites wired. Player body stays placeholder — no player.png provided.
- **Modular, composable.** Prefer small focused scripts over large managers.
- This is a real project being actively developed toward a shipped product, not a learning exercise.
- See `GDD.md` for full design decisions and prototype success criteria.

## Development phases
| Phase | Feature | Status |
|---|---|---|
| 1 | Player movement, sword, enemy AI, transitions, pixel rendering, Game Over | ✅ Done |
| 2 | Room system (Room1↔Room2, doors, spawn points, health persistence) | ✅ Done |
| 3 | Items — HeartPickup, 30% drop from slimes on death | ✅ Done |
| 4 | Main menu — title screen, Play/Quit | ✅ Done |
| 5 | Pause menu — ESC pauses, Continue/Exit | ✅ Done |
| 6 | Real sprites — wire tileset_forest.png, slime.png, sword.png | ✅ Done |

## Folder structure
```
scenes/
  player/       → Player.tscn + Player.gd
  enemies/      → Slime.tscn, BaseEnemy.gd, Slime.gd
  world/        → Room.gd, Door.tscn, Door.gd
    rooms/      → Room1_Tutorial.tscn, Room2_Challenge.tscn
  items/        → HeartPickup.tscn, HeartPickup.gd
  ui/           → HealthUI.tscn, GameOver.tscn, MainMenu.tscn
scripts/
  combat/       → HitBox.gd, HurtBox.gd, HealthComponent.gd
  components/   → StateMachine.gd, PixelCamera.gd, PlaceholderSprite.gd
  data/         → Constants.gd
autoloads/      → EventBus.gd, GameManager.gd, SceneManager.gd, InputHandler.gd, PauseMenu.gd
assets/
  sprites/      → player/sword.png (wired), enemies/slime.png (wired), world/tileset_forest.png (wired), world/bush.png (not used yet)
Tools/          → gen_sprites.py
```
