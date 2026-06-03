extends CanvasLayer
## Pantalla de título del juego. Primera escena visible al iniciar.
##
## Responsabilidades:
##   - Resetea el estado global (despausa árbol, estado MENU).
##   - "JUGAR" inicia el juego desde Sala1 via SceneManager.
##   - "SALIR" cierra la aplicación.
##
## Jerarquía (construida en código):
##   MainMenu (CanvasLayer, layer=0)
##     └─ Fondo   (ColorRect, pantalla completa)
##     └─ Caja    (VBoxContainer, centrado)
##           └─ Titulo   (Label "THE VILLAGE")
##           └─ BtnJugar (Button "JUGAR")
##           └─ BtnSalir (Button "SALIR")

func _ready() -> void:
	layer = 0
	## Resetear estado global: garantiza que no quede ninguna pausa residual
	## de una sesión anterior (ej: volver al menú desde el menú de pausa).
	get_tree().paused = false
	GameManager.set_state(GameManager.GameState.MENU)
	_construir_ui()

# ─── Construcción de la UI ────────────────────────────────────────────────────

func _construir_ui() -> void:
	var fondo := ColorRect.new()
	fondo.anchor_right  = 1.0
	fondo.anchor_bottom = 1.0
	fondo.color = Color(0.04, 0.07, 0.12)
	add_child(fondo)

	var caja := VBoxContainer.new()
	caja.anchor_left   = 0.5
	caja.anchor_top    = 0.5
	caja.anchor_right  = 0.5
	caja.anchor_bottom = 0.5
	caja.offset_left   = -60.0
	caja.offset_top    = -40.0
	caja.offset_right  =  60.0
	caja.offset_bottom =  40.0
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_theme_constant_override("separation", 10)
	add_child(caja)

	var titulo := Label.new()
	titulo.text = "THE VILLAGE"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 18)
	caja.add_child(titulo)

	## Separador visual entre título y botones
	var separador := Control.new()
	separador.custom_minimum_size = Vector2(0.0, 8.0)
	caja.add_child(separador)

	var btn_jugar := Button.new()
	btn_jugar.text = "JUGAR"
	btn_jugar.pressed.connect(_on_jugar_presionado)
	caja.add_child(btn_jugar)

	var btn_salir := Button.new()
	btn_salir.text = "SALIR"
	btn_salir.pressed.connect(_on_salir_presionado)
	caja.add_child(btn_salir)

# ─── Señales ──────────────────────────────────────────────────────────────────

func _on_jugar_presionado() -> void:
	SceneManager.go_to_room(Constants.SCENE_SALA1)

func _on_salir_presionado() -> void:
	get_tree().quit()
