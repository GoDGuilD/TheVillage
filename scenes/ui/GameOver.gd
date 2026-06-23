extends CanvasLayer
## "Game Over" screen. Shown automatically when the player dies.
##
## Architecture:
##   - Connects to EventBus.player_died in its own _ready().
##   - Instantiated by HealthUI and added to root when the player dies.
##   - On retry, uses SceneManager to do a clean fade to Room1.
##
## Hierarchy (created in code to avoid .tscn dependencies):
##   GameOver (CanvasLayer, layer=127)
##     └─ Background  (ColorRect, full dark screen)
##     └─ Box         (VBoxContainer, centered on screen)
##           └─ Title    (Label, "GAME OVER")
##           └─ Button   (Button, "RETRY")

## Seconds to wait before showing the screen (lets the last animation play out)
const SHOW_DELAY := 0.8

func _ready() -> void:
	## Layer 127: above the game UI but below the SceneManager fade (128).
	layer = 127
	visible = false
	## PROCESS_MODE_ALWAYS guarantees the timer runs even while the tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	## Start directly: this scene is instantiated AS A RESULT OF player_died,
	## so the signal has already been emitted. No need to listen for it again.
	_on_player_died()

# ─── UI construction ──────────────────────────────────────────────────────────

func _build_ui() -> void:
	## Semi-transparent background that visually blocks the game underneath.
	var background := ColorRect.new()
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.color = Color(0.0, 0.0, 0.0, 0.78)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	## Container centered on screen (320×180 viewport).
	var box := VBoxContainer.new()
	box.anchor_left   = 0.5
	box.anchor_top    = 0.5
	box.anchor_right  = 0.5
	box.anchor_bottom = 0.5
	box.offset_left   = -55.0
	box.offset_top    = -22.0
	box.offset_right  =  55.0
	box.offset_bottom =  22.0
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	add_child(box)

	var title := Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	box.add_child(title)

	var button := Button.new()
	button.text = "RETRY"
	button.pressed.connect(_on_retry_pressed)
	box.add_child(button)

# ─── Signals ──────────────────────────────────────────────────────────────────

func _on_player_died() -> void:
	await get_tree().create_timer(SHOW_DELAY, true).timeout
	visible = true

func _on_retry_pressed() -> void:
	## Remove this node before the transition.
	## It was added to root (not to the scene), so it isn't destroyed automatically
	## on scene change — it must be freed manually.
	## The SceneManager fade (layer 128) visually covers its disappearance.
	queue_free()
	SceneManager.go_to_room(Constants.SCENE_ROOM1)
