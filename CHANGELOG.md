# Changelog — The Village

All relevant project changes are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added
- `scripts/components/PixelCamera.gd` — Camera2D with snapping to integer pixels (anti-shimmer)
- `scenes/player/Player.gd` — complete PlayerController with StateMachine, smooth acceleration and KNOCKBACK state
- `scenes/player/Player.tscn` — adds StateMachine, KnockbackTimer nodes and PixelCamera script
- `autoloads/InputHandler.gd` — input abstraction layer with discrete signals and movement polling
- `autoloads/SceneManager.gd` — room transitions with fade
- `autoloads/GameManager.gd` — rewritten with `GameState` enum and enemy registry
- `autoloads/EventBus.gd` — expanded with game, audio and room signals
- `scripts/data/Constants.gd` — single source of configurable values (`class_name Constants`)
- `scripts/components/StateMachine.gd` — reusable FSM driven by naming convention
- Input actions `move_left/right/up/down`, `interact`, `pause_game` in `project.godot`
- Full analog stick and D-pad support via `InputEventJoypadMotion` in InputMap
- `Player.gd` migrated: reads from `InputHandler`, uses `Constants`, no direct `Input` calls

### Changed
- `scripts/combat/HurtBox.gd` — `hurt` signal now passes `source_position: Vector2` for precise knockback
- `scenes/enemies/BaseEnemy.gd` — `_on_hurt` updated to match HurtBox's new signature
- `scripts/components/StateMachine.gd` — migrated from `_process` to `_physics_process`
- `scripts/data/Constants.gd` — added `PLAYER_ACCELERATION` and `PLAYER_FRICTION`
- `project.godot` — 320×180 window with `canvas_items` stretch + `integer` scale for pixel-perfect rendering
- Autoloads moved from `scripts/autoloads/` → `autoloads/` (root level)
- `project.godot` updated with new autoload paths

### Structure
- Complete project folder structure
- `EventBus` — global signal bus for decoupled communication
- `GameManager` — singleton with a reference to the player
- `HealthComponent` — reusable health component (child Node)
- `HitBox` / `HurtBox` — layer-based damage system (7 layers)
- `Player.tscn` — player with 8-direction movement, sword attack and iFrames
- `BaseEnemy.gd` — base class with state machine (IDLE / CHASE / DEAD)
- `Slime.tscn` — enemy with random patrol and radius-based chase
- `HealthUI.tscn` — reactive heart HUD via EventBus
- `World.tscn` — root scene with TileMapLayer, player and 2 Slimes
- `attack` input action mapped to Space and the gamepad's South button
- 2D collision layer names in `project.godot`

---

## [0.0.1] — 2026-05-25

### Added
- Initial repository with `.gitignore` for Godot 4
- `project.godot` named "The Village", Mobile/D3D12 renderer
