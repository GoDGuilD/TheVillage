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

### Key systems
- **Combat**: `HitBox` (Area2D, layer) + `HurtBox` (Area2D, mask + signal `hurt`)
  - ⚠️ Sword HitBox requiere toggling de AMBOS `monitoring` Y `monitorable` — solo `monitoring` causa daño fantasma a enemigos cercanos
- **Player FSM**: states defined as `state_X_enter/update/exit()` methods, driven by `StateMachine.gd`
- **Enemies**: extend `BaseEnemy` → override `_update_idle()` and `_update_chase()`
- **Health**: `HealthComponent` node (composable), emits `health_changed` / `died`
- **Room system**: `Room.gd` base script — genera suelo, paredes, bloquea cámara al viewport, maneja spawn via `EventBus.room_entered`
- **Doors**: `Door.tscn` (Area2D trigger) — exports `target_scene` + `spawn_id`, detecta Player body (mask=2)
- **Game Over**: `GameOver.tscn` instanciado por `HealthUI` y añadido a root al morir. Se libera con `queue_free()` al reintentar.
- **Placeholders**: `PlaceholderSprite.inject()` fills empty SpriteFrames — safe to replace with real art

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
- Main scene: `res://scenes/world/rooms/Sala1_Tutorial.tscn`
- `Constants.SCENE_SALA1` / `Constants.SCENE_SALA2` — usar estas constantes, nunca strings hardcodeados

## Development philosophy
- **Only implement what's requested.** No preemptive systems.
- **Comments in Spanish.** Variable/method names in English (GDScript convention).
- **Placeholders are intentional.** Real sprites/audio come in Phase 6.
- **Modular, composable.** Prefer small focused scripts over large managers.
- See `GDD.md` for full design decisions and prototype success criteria.

## Development phases
| Phase | Feature | Status |
|---|---|---|
| 1 | Player movement, sword, enemy AI, transitions, pixel rendering, Game Over | ✅ Done |
| 2 | Room system (Sala1↔Sala2, doors, spawn points, health persistence) | ✅ Done |
| 3 | Items — HeartPickup, 30% drop from slimes on death | 🔲 Next |
| 4 | Main menu — title screen, Play/Quit | 🔲 Pending |
| 5 | Pause menu — ESC pauses, Continue/Exit | 🔲 Pending |
| 6 | Real sprites — wire tileset_forest.png, slime.png, sword.png | 🔲 Pending |

## Folder structure
```
scenes/
  player/       → Player.tscn + Player.gd
  enemies/      → Slime.tscn, BaseEnemy.gd, Slime.gd
  world/        → Room.gd, Door.tscn, Door.gd
    rooms/      → Sala1_Tutorial.tscn, Sala2_Desafio.tscn
  ui/           → HealthUI.tscn, GameOver.tscn
scripts/
  combat/       → HitBox.gd, HurtBox.gd, HealthComponent.gd
  components/   → StateMachine.gd, PixelCamera.gd, PlaceholderSprite.gd
  data/         → Constants.gd
autoloads/      → EventBus.gd, GameManager.gd, SceneManager.gd, InputHandler.gd
assets/
  sprites/      → player/, enemies/, world/ (reales, aún sin conectar)
Tools/          → gen_sprites.py
```
