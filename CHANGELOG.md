# Changelog — The Village

Todos los cambios relevantes del proyecto se documentan aquí.  
Formato basado en [Keep a Changelog](https://keepachangelog.com/es/1.0.0/).

---

## [Unreleased]

### Added
- `scripts/components/PixelCamera.gd` — Camera2D con snap a píxeles enteros (anti-shimmer)
- `scenes/player/Player.gd` — PlayerController completo con StateMachine, aceleración suave y estado KNOCKBACK
- `scenes/player/Player.tscn` — agrega nodos StateMachine, KnockbackTimer y PixelCamera script
- `autoloads/InputHandler.gd` — capa de abstracción de input con señales discretas y polling de movimiento
- `autoloads/SceneManager.gd` — transiciones de sala con fade
- `autoloads/GameManager.gd` — reescrito con enum `GameState` y registro de enemigos
- `autoloads/EventBus.gd` — expandido con señales de juego, audio y salas
- `scripts/data/Constants.gd` — fuente única de valores configurables (`class_name Constants`)
- `scripts/components/StateMachine.gd` — FSM reutilizable por convención de nombres
- Acciones de input `move_left/right/up/down`, `interact`, `pause_game` en `project.godot`
- Soporte completo de stick analógico y D-pad via `InputEventJoypadMotion` en InputMap
- `Player.gd` migrado: lee de `InputHandler`, usa `Constants`, sin `Input` directo

### Changed
- `scripts/combat/HurtBox.gd` — señal `hurt` ahora pasa `source_position: Vector2` para knockback preciso
- `scenes/enemies/BaseEnemy.gd` — `_on_hurt` actualizado con firma nueva de HurtBox
- `scripts/components/StateMachine.gd` — migrado de `_process` a `_physics_process`
- `scripts/data/Constants.gd` — añadidas `PLAYER_ACCELERATION` y `PLAYER_FRICTION`
- `project.godot` — ventana 320×180 con stretch `canvas_items` + `integer` scale para pixel-perfect
- Autoloads movidos de `scripts/autoloads/` → `autoloads/` (nivel raíz)
- `project.godot` actualizado con nuevos paths de autoloads

### Structure
- Estructura completa de carpetas del proyecto
- `EventBus` — bus de señales global para comunicación desacoplada
- `GameManager` — singleton con referencia al jugador
- `HealthComponent` — componente reutilizable de vida (Node hijo)
- `HitBox` / `HurtBox` — sistema de daño por capas de colisión (7 layers)
- `Player.tscn` — jugador con movimiento 8 dirs, ataque con espada e iFrames
- `BaseEnemy.gd` — clase base con máquina de estados (IDLE / CHASE / DEAD)
- `Slime.tscn` — enemigo con patrulla aleatoria y persecución por radio
- `HealthUI.tscn` — HUD de corazones reactivo via EventBus
- `World.tscn` — escena raíz con TileMapLayer, jugador y 2 Slimes
- Acción de input `attack` mapeada a Espacio y botón Sur del gamepad
- Nombres de capas de colisión 2D en `project.godot`

---

## [0.0.1] — 2026-05-25

### Added
- Repositorio inicial con `.gitignore` para Godot 4
- `project.godot` con nombre "The Village", renderer Mobile/D3D12
