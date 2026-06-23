extends CanvasLayer
## Pause menu. Persistent autoload — not destroyed on room change.
##
## Listens to InputHandler.pause_pressed and toggles between PLAYING and PAUSED.
## Only active during the PLAYING state; ignored in MENU and GAME_OVER.
##
## Hierarchy (built in code):
##   PauseMenu (CanvasLayer, layer=125, PROCESS_MODE_ALWAYS)
##     └─ Fondo        (semi-transparent ColorRect)
##     └─ Caja         (centered VBoxContainer)
##           └─ Titulo (Label "PAUSA")
##           └─ BtnContinuar  (Button "CONTINUAR")
##           └─ BtnMenu       (Button "SALIR AL MENÚ")

## Prevents toggling pause during room transitions.
var _transitioning: bool = false

func _ready() -> void:
	layer = 125   ## Below GameOver (127) and SceneManager (128)
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_construir_ui()
	InputHandler.pause_pressed.connect(_on_pause_pressed)
	SceneManager.transition_started.connect(_on_transition_started)
	SceneManager.transition_finished.connect(_on_transition_finished)

# ─── UI construction ──────────────────────────────────────────────────────────

func _construir_ui() -> void:
	var fondo := ColorRect.new()
	fondo.anchor_right  = 1.0
	fondo.anchor_bottom = 1.0
	fondo.color = Color(0.0, 0.0, 0.0, 0.72)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)

	var caja := VBoxContainer.new()
	caja.anchor_left   = 0.5
	caja.anchor_top    = 0.5
	caja.anchor_right  = 0.5
	caja.anchor_bottom = 0.5
	caja.offset_left   = -60.0
	caja.offset_top    = -32.0
	caja.offset_right  =  60.0
	caja.offset_bottom =  32.0
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_theme_constant_override("separation", 8)
	add_child(caja)

	var titulo := Label.new()
	titulo.text = "PAUSA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 14)
	caja.add_child(titulo)

	var btn_continuar := Button.new()
	btn_continuar.text = "CONTINUAR"
	btn_continuar.pressed.connect(_on_continuar_presionado)
	caja.add_child(btn_continuar)

	var btn_menu := Button.new()
	btn_menu.text = "SALIR AL MENÚ"
	btn_menu.pressed.connect(_on_menu_presionado)
	caja.add_child(btn_menu)

# ─── Pause toggle ──────────────────────────────────────────────────────────────

func _on_pause_pressed() -> void:
	## Ignore if a transition is in progress or the state isn't PLAYING/PAUSED.
	if _transitioning:
		return
	match GameManager.state:
		GameManager.GameState.PLAYING: _pausar()
		GameManager.GameState.PAUSED:  _reanudar()

func _pausar() -> void:
	visible = true
	GameManager.set_state(GameManager.GameState.PAUSED)

func _reanudar() -> void:
	visible = false
	GameManager.set_state(GameManager.GameState.PLAYING)

# ─── Buttons ───────────────────────────────────────────────────────────────────

func _on_continuar_presionado() -> void:
	_reanudar()

func _on_menu_presionado() -> void:
	visible = false
	## Unpause the tree BEFORE calling SceneManager:
	## go_to_room awaits tweens that don't advance while paused=true.
	get_tree().paused = false
	SceneManager.go_to_room(Constants.SCENE_MAIN_MENU)

# ─── Transitions ──────────────────────────────────────────────────────────────

func _on_transition_started() -> void:
	_transitioning = true
	visible = false

func _on_transition_finished() -> void:
	_transitioning = false
