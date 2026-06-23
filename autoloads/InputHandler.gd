extends Node
## Input abstraction layer. The only file that knows action names.
##
## Player, enemies and UI read from here — not from Input directly.
## This enables remapping, input-free cutscenes and testing without hardware.
##
## Usage pattern:
##   - Continuous movement → InputHandler.get_move_vector()
##   - Discrete actions → connect to InputHandler.attack_pressed, etc.

# ─── Action constants ────────────────────────────────────────────────────────
## Canonical action names. If you rename an action in the InputMap,
## only change it here — the rest of the code doesn't need to know.
const MOVE_LEFT  := &"move_left"
const MOVE_RIGHT := &"move_right"
const MOVE_UP    := &"move_up"
const MOVE_DOWN  := &"move_down"
const ATTACK     := &"attack"
const INTERACT   := &"interact"
const PAUSE_GAME := &"pause_game"

# ─── Signals (discrete actions — emitted once per press) ────────────────────
signal attack_pressed()
signal interact_pressed()
signal pause_pressed()

# ─── State ───────────────────────────────────────────────────────────────────
## Disables ALL player input. Use during cutscenes, game over, menus.
var controller_enabled: bool = true

# ─── Polling (continuous movement) ───────────────────────────────────────────

func get_move_vector() -> Vector2:
	## Returns a normalized movement vector.
	## Works with keyboard, arrows, D-pad and analog stick with no extra code.
	if not controller_enabled:
		return Vector2.ZERO
	return Input.get_vector(MOVE_LEFT, MOVE_RIGHT, MOVE_UP, MOVE_DOWN)

func is_moving() -> bool:
	return get_move_vector() != Vector2.ZERO

# ─── Input event (discrete actions) ──────────────────────────────────────────

func _input(event: InputEvent) -> void:
	## _input() instead of _process() to avoid emitting signals every frame.
	## Only called when there's an actual input event.
	if not controller_enabled:
		return

	if event.is_action_pressed(ATTACK, false):   # false = no repeat while held
		attack_pressed.emit()
		get_viewport().set_input_as_handled()

	if event.is_action_pressed(INTERACT, false):
		interact_pressed.emit()
		get_viewport().set_input_as_handled()

	if event.is_action_pressed(PAUSE_GAME, false):
		pause_pressed.emit()
		get_viewport().set_input_as_handled()

# ─── Remapping (API for a future settings screen) ────────────────────────────

func remap_action(action: StringName, new_event: InputEvent) -> void:
	## Replaces all events of an action with a new one.
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, new_event)

func reset_action_to_default(_action: StringName) -> void:
	## Restores an action's events to those defined in project.godot.
	InputMap.load_from_project_settings()
