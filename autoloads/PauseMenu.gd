extends CanvasLayer
## Pause menu. Persistent autoload — not destroyed on room change.
##
## Listens to InputHandler.pause_pressed and toggles between PLAYING and PAUSED.
## Only active during the PLAYING state; ignored in MENU and GAME_OVER.
##
## Hierarchy (built in code):
##   PauseMenu (CanvasLayer, layer=125, PROCESS_MODE_ALWAYS)
##     └─ Background     (semi-transparent ColorRect)
##     └─ Box            (centered VBoxContainer)
##           └─ Title       (Label "PAUSED")
##           └─ ContinueButton  (Button "CONTINUE")
##           └─ MenuButton      (Button "EXIT TO MENU")

## Prevents toggling pause during room transitions.
var _transitioning: bool = false

func _ready() -> void:
	layer = 125   ## Below GameOver (127) and SceneManager (128)
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	InputHandler.pause_pressed.connect(_on_pause_pressed)
	SceneManager.transition_started.connect(_on_transition_started)
	SceneManager.transition_finished.connect(_on_transition_finished)

# ─── UI construction ──────────────────────────────────────────────────────────

func _build_ui() -> void:
	var background := ColorRect.new()
	background.anchor_right  = 1.0
	background.anchor_bottom = 1.0
	background.color = Color(0.0, 0.0, 0.0, 0.72)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var box := VBoxContainer.new()
	box.anchor_left   = 0.5
	box.anchor_top    = 0.5
	box.anchor_right  = 0.5
	box.anchor_bottom = 0.5
	box.offset_left   = -60.0
	box.offset_top    = -32.0
	box.offset_right  =  60.0
	box.offset_bottom =  32.0
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	add_child(box)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	box.add_child(title)

	var continue_button := Button.new()
	continue_button.text = "CONTINUE"
	continue_button.pressed.connect(_on_continue_pressed)
	box.add_child(continue_button)

	var menu_button := Button.new()
	menu_button.text = "EXIT TO MENU"
	menu_button.pressed.connect(_on_menu_pressed)
	box.add_child(menu_button)

# ─── Pause toggle ──────────────────────────────────────────────────────────────

func _on_pause_pressed() -> void:
	## Ignore if a transition is in progress or the state isn't PLAYING/PAUSED.
	if _transitioning:
		return
	match GameManager.state:
		GameManager.GameState.PLAYING: _pause()
		GameManager.GameState.PAUSED:  _resume()

func _pause() -> void:
	visible = true
	GameManager.set_state(GameManager.GameState.PAUSED)

func _resume() -> void:
	visible = false
	GameManager.set_state(GameManager.GameState.PLAYING)

# ─── Buttons ───────────────────────────────────────────────────────────────────

func _on_continue_pressed() -> void:
	_resume()

func _on_menu_pressed() -> void:
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
