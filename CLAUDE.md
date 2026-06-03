# The Village — Godot Project

Action-RPG top-down 2D, inspired by Zelda: A Link to the Past. Engine: Godot 4.6.3.

## Running the project
Open `D:\SOFTWARE\GoDot\Godot_v4.6.3-stable_win64.exe` → Open this project → F5 to run.
MCP plugin (`addons/godot_mcp`) must be enabled for Claude Code integration.

## Architecture

### Autoloads (load order matters)
| Autoload | Responsabilidad |
|---|---|
| `EventBus` | Bus de señales. Solo señales, cero lógica. |
| `GameManager` | Estado global (MENU/PLAYING/PAUSED/GAME_OVER), registro de entidades, persiste `player_health` entre salas. |
| `SceneManager` | Fade + cambio de sala. Usar `go_to_room(path, spawn_id)`. CanvasLayer layer=128. |
| `InputHandler` | Abstracción de input. Nunca usar `Input` directamente. Persiste entre escenas — Player._ready() siempre resetea `controller_enabled = true`. |
| `PauseMenu` | Menú de pausa. CanvasLayer layer=125, PROCESS_MODE_ALWAYS. Escucha `InputHandler.pause_pressed`. Solo activo en estado PLAYING/PAUSED. |

### Key systems
- **Combat**: `HitBox` (Area2D, layer) + `HurtBox` (Area2D, mask + signal `hurt`)
  - ⚠️ Sword HitBox requiere toggling de AMBOS `monitoring` Y `monitorable` — solo `monitoring` causa daño fantasma a enemigos cercanos
- **Player FSM**: states defined as `state_X_enter/update/exit()` methods, driven by `StateMachine.gd`
- **Enemies**: extend `BaseEnemy` → override `_update_idle()` and `_update_chase()`
- **Health**: `HealthComponent` node (composable), emits `health_changed` / `died`
- **Room system**: `Room.gd` base script — genera suelo, paredes, bloquea cámara al viewport, maneja spawn via `EventBus.room_entered`
- **Doors**: `Door.tscn` (Area2D trigger) — exports `target_scene` + `spawn_id`, detecta Player body (mask=2)
- **Game Over**: `GameOver.tscn` instanciado por `HealthUI` y añadido a root al morir. Se libera con `queue_free()` al reintentar.
- **Main Menu**: `MainMenu.tscn` es la main_scene. CanvasLayer layer=0. Resetea pausa y estado MENU en `_ready()`.
- **Pause Menu**: autoload `PauseMenu.gd`. ESC toggle PLAYING↔PAUSED. "SALIR AL MENÚ" despausa antes de `go_to_room()` — los tweens del SceneManager no avanzan con `paused=true`.
- **Sprites**: `PlaceholderSprite.inject()` auto-skips if SpriteFrames already have frames — real sprites in Slime.tscn and sword in Player.tscn/Player.gd. Player body stays placeholder (no player.png provided).

### Gotchas conocidos (bugs ya resueltos — no repetir)
| Problema | Causa | Solución |
|---|---|---|
| Slimes mueren al tocar al jugador | `monitorable=true` en sword HitBox activa HurtBox enemigo | Toggling de `monitorable` junto con `monitoring` |
| GameOver no aparecía | Se conectaba a `player_died` pero la señal ya había sido emitida | Llamar `_on_jugador_muerto()` directamente en `_ready()` |
| Health bar vacía al reintentar | `save_player_health()` guardaba 0 (jugador muerto) sobre el -1 | No guardar si `current_health <= 0` |
| GameOver persiste tras reintentar | Añadido a root, no se destruye con el cambio de escena | `queue_free()` antes de `go_to_room()` |
| Input bloqueado tras reintentar | `InputHandler.controller_enabled=false` persiste entre escenas | `Player._ready()` siempre resetea a `true` |

### Collision layers (project.godot)
| Layer | Nombre | Valor bitmask |
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
- Camera: `PixelCamera.gd` en Camera2D hijo del Player (redondea posición a enteros)
- Camera limits: Room.gd los fija al viewport para sala de una pantalla (sin scroll)

### Scene paths importantes
- Main scene: `res://scenes/ui/MainMenu.tscn`
- `Constants.SCENE_SALA1` / `Constants.SCENE_SALA2` / `Constants.SCENE_MAIN_MENU` / `Constants.SCENE_HEART_PICKUP` — usar estas constantes, nunca strings hardcodeados
- `Constants.HEART_DROP_CHANCE = 0.30` — probabilidad de drop de HeartPickup al morir un Slime

## Development philosophy
- **Only implement what's requested.** No preemptive systems.
- **Comments in Spanish.** Variable/method names in English (GDScript convention).
- **Prototype is complete.** All 6 phases done. Real sprites wired. Player body stays placeholder — no player.png provided.
- **Modular, composable.** Prefer small focused scripts over large managers.
- See `GDD.md` for full design decisions and prototype success criteria.

## Development phases
| Phase | Feature | Status |
|---|---|---|
| 1 | Player movement, sword, enemy AI, transitions, pixel rendering, Game Over | ✅ Done |
| 2 | Room system (Sala1↔Sala2, doors, spawn points, health persistence) | ✅ Done |
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
    rooms/      → Sala1_Tutorial.tscn, Sala2_Desafio.tscn
  items/        → HeartPickup.tscn, HeartPickup.gd
  ui/           → HealthUI.tscn, GameOver.tscn, MainMenu.tscn
scripts/
  combat/       → HitBox.gd, HurtBox.gd, HealthComponent.gd
  components/   → StateMachine.gd, PixelCamera.gd, PlaceholderSprite.gd
  data/         → Constants.gd
autoloads/      → EventBus.gd, GameManager.gd, SceneManager.gd, InputHandler.gd, PauseMenu.gd
assets/
  sprites/      → player/sword.png (wired), enemies/slime.png (wired), world/tileset_forest.png (wired), world/bush.png (no usado aún)
Tools/          → gen_sprites.py
```
