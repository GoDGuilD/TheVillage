extends Node
## Capa de abstracción de input. El único archivo que conoce nombres de acciones.
##
## Jugador, enemigos y UI leen de aquí — no de Input directamente.
## Esto permite remapping, cutscenas sin input y testing sin hardware.
##
## Patrón de uso:
##   - Movimiento continuo → InputHandler.get_move_vector()
##   - Acciones discretas → conectar a InputHandler.attack_pressed, etc.

# ─── Constantes de acción ────────────────────────────────────────────────────
## Nombres canónicos de las acciones. Si renombras una acción en el InputMap,
## solo cambia aquí — el resto del código no se entera.
const MOVE_LEFT  := &"move_left"
const MOVE_RIGHT := &"move_right"
const MOVE_UP    := &"move_up"
const MOVE_DOWN  := &"move_down"
const ATTACK     := &"attack"
const INTERACT   := &"interact"
const PAUSE_GAME := &"pause_game"

# ─── Señales (acciones discretas — se emiten una vez por pulsación) ──────────
signal attack_pressed()
signal interact_pressed()
signal pause_pressed()

# ─── Estado ──────────────────────────────────────────────────────────────────
## Desactiva TODO el input del jugador. Úsalo en cutscenas, game over, menús.
var controller_enabled: bool = true

# ─── Polling (movimiento continuo) ───────────────────────────────────────────

func get_move_vector() -> Vector2:
	## Devuelve vector de movimiento normalizado.
	## Funciona con teclado, flechas, D-pad y stick analógico sin código extra.
	if not controller_enabled:
		return Vector2.ZERO
	return Input.get_vector(MOVE_LEFT, MOVE_RIGHT, MOVE_UP, MOVE_DOWN)

func is_moving() -> bool:
	return get_move_vector() != Vector2.ZERO

# ─── Input event (acciones discretas) ────────────────────────────────────────

func _input(event: InputEvent) -> void:
	## _input() en lugar de _process() para no emitir señales cada frame.
	## Se llama solo cuando hay un evento real de input.
	if not controller_enabled:
		return

	if event.is_action_pressed(ATTACK, false):   # false = no repetición al mantener
		attack_pressed.emit()
		get_viewport().set_input_as_handled()

	if event.is_action_pressed(INTERACT, false):
		interact_pressed.emit()
		get_viewport().set_input_as_handled()

	if event.is_action_pressed(PAUSE_GAME, false):
		pause_pressed.emit()
		get_viewport().set_input_as_handled()

# ─── Remapping (API para futura pantalla de configuración) ───────────────────

func remap_action(action: StringName, new_event: InputEvent) -> void:
	## Sustituye todos los eventos de una acción por uno nuevo.
	## Útil para una pantalla de "Pulsa la tecla para..." en settings.
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, new_event)

func reset_action_to_default(action: StringName) -> void:
	## Restaura los eventos de una acción a los definidos en project.godot.
	InputMap.load_from_project_settings()
