extends CanvasLayer
## "Game Over" screen. Shown automatically when the player dies.
##
## Architecture:
##   - Connects to EventBus.player_died in its own _ready().
##   - Instantiated by HealthUI and added to root when the player dies.
##   - On retry, uses SceneManager to do a clean fade to Sala1.
##
## Hierarchy (created in code to avoid .tscn dependencies):
##   GameOver (CanvasLayer, layer=127)
##     └─ Fondo     (ColorRect, full dark screen)
##     └─ Caja      (VBoxContainer, centered on screen)
##           └─ Titulo   (Label, "GAME OVER")
##           └─ Boton    (Button, "REINTENTAR")

## Seconds to wait before showing the screen (lets the last animation play out)
const DEMORA_MOSTRAR := 0.8

func _ready() -> void:
	## Layer 127: above the game UI but below the SceneManager fade (128).
	layer = 127
	visible = false
	## PROCESS_MODE_ALWAYS guarantees the timer runs even while the tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_construir_ui()
	## Start directly: this scene is instantiated AS A RESULT OF player_died,
	## so the signal has already been emitted. No need to listen for it again.
	_on_jugador_muerto()

# ─── UI construction ──────────────────────────────────────────────────────────

func _construir_ui() -> void:
	## Semi-transparent background that visually blocks the game underneath.
	var fondo := ColorRect.new()
	fondo.anchor_right = 1.0
	fondo.anchor_bottom = 1.0
	fondo.color = Color(0.0, 0.0, 0.0, 0.78)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)

	## Container centered on screen (320×180 viewport).
	var caja := VBoxContainer.new()
	caja.anchor_left   = 0.5
	caja.anchor_top    = 0.5
	caja.anchor_right  = 0.5
	caja.anchor_bottom = 0.5
	caja.offset_left   = -55.0
	caja.offset_top    = -22.0
	caja.offset_right  =  55.0
	caja.offset_bottom =  22.0
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_theme_constant_override("separation", 8)
	add_child(caja)

	var titulo := Label.new()
	titulo.text = "GAME OVER"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 14)
	caja.add_child(titulo)

	var boton := Button.new()
	boton.text = "REINTENTAR"
	boton.pressed.connect(_on_reintentar_presionado)
	caja.add_child(boton)

# ─── Signals ──────────────────────────────────────────────────────────────────

func _on_jugador_muerto() -> void:
	await get_tree().create_timer(DEMORA_MOSTRAR, true).timeout
	visible = true

func _on_reintentar_presionado() -> void:
	## Remove this node before the transition.
	## It was added to root (not to the scene), so it isn't destroyed automatically
	## on scene change — it must be freed manually.
	## The SceneManager fade (layer 128) visually covers its disappearance.
	queue_free()
	SceneManager.go_to_room(Constants.SCENE_SALA1)
