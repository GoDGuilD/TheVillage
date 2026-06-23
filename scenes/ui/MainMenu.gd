extends CanvasLayer
## Game title screen. First scene visible on startup.
##
## Responsibilities:
##   - Resets global state (unpauses the tree, MENU state).
##   - "PLAY" starts the game from Room1 via SceneManager.
##   - "QUIT" quits the application.
##
## Hierarchy (built in code):
##   MainMenu (CanvasLayer, layer=0)
##     └─ Background  (ColorRect, full screen)
##     └─ Box         (VBoxContainer, centered)
##           └─ Title       (Label "THE VILLAGE")
##           └─ PlayButton  (Button "PLAY")
##           └─ QuitButton  (Button "QUIT")

func _ready() -> void:
	layer = 0
	## Reset global state: guarantees no leftover pause
	## from a previous session (e.g. returning to the menu from the pause menu).
	get_tree().paused = false
	GameManager.set_state(GameManager.GameState.MENU)
	_build_ui()

# ─── UI construction ──────────────────────────────────────────────────────────

func _build_ui() -> void:
	var background := ColorRect.new()
	background.anchor_right  = 1.0
	background.anchor_bottom = 1.0
	background.color = Color(0.04, 0.07, 0.12)
	add_child(background)

	var box := VBoxContainer.new()
	box.anchor_left   = 0.5
	box.anchor_top    = 0.5
	box.anchor_right  = 0.5
	box.anchor_bottom = 0.5
	box.offset_left   = -60.0
	box.offset_top    = -40.0
	box.offset_right  =  60.0
	box.offset_bottom =  40.0
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	add_child(box)

	var title := Label.new()
	title.text = "THE VILLAGE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	box.add_child(title)

	## Visual separator between title and buttons
	var separator := Control.new()
	separator.custom_minimum_size = Vector2(0.0, 8.0)
	box.add_child(separator)

	var play_button := Button.new()
	play_button.text = "PLAY"
	play_button.pressed.connect(_on_play_pressed)
	box.add_child(play_button)

	var quit_button := Button.new()
	quit_button.text = "QUIT"
	quit_button.pressed.connect(_on_quit_pressed)
	box.add_child(quit_button)

# ─── Signals ──────────────────────────────────────────────────────────────────

func _on_play_pressed() -> void:
	SceneManager.go_to_room(Constants.SCENE_ROOM1)

func _on_quit_pressed() -> void:
	get_tree().quit()
