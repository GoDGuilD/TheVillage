extends CanvasLayer
## Pantalla de "Game Over". Se muestra automáticamente cuando el jugador muere.
##
## Arquitectura:
##   - Se conecta a EventBus.player_died en su propio _ready().
##   - HealthUI la instancia y la añade al root cuando el jugador muere.
##   - Al reintentar usa SceneManager para hacer un fade limpio a Sala1.
##
## Jerarquía (creada en código para evitar dependencias de .tscn):
##   GameOver (CanvasLayer, layer=127)
##     └─ Fondo     (ColorRect, pantalla completa oscura)
##     └─ Caja      (VBoxContainer, centrado en pantalla)
##           └─ Titulo   (Label, "GAME OVER")
##           └─ Boton    (Button, "REINTENTAR")

## Segundos de espera antes de mostrar la pantalla (deja ver la última animación)
const DEMORA_MOSTRAR := 0.8

func _ready() -> void:
	## Capa 127: encima de la UI del juego pero debajo del fade del SceneManager (128).
	layer = 127
	visible = false
	## PROCESS_MODE_ALWAYS garantiza que el timer funcione aunque el árbol esté pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_construir_ui()
	## Arrancar directamente: esta escena se instancia COMO CONSECUENCIA de player_died,
	## así que la señal ya se emitió. No hay que escucharla de nuevo.
	_on_jugador_muerto()

# ─── Construcción de la UI ────────────────────────────────────────────────────

func _construir_ui() -> void:
	## Fondo semi-transparente que bloquea visualmente el juego debajo.
	var fondo := ColorRect.new()
	fondo.anchor_right = 1.0
	fondo.anchor_bottom = 1.0
	fondo.color = Color(0.0, 0.0, 0.0, 0.78)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)

	## Contenedor centrado en la pantalla (viewport 320×180).
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

# ─── Señales ──────────────────────────────────────────────────────────────────

func _on_jugador_muerto() -> void:
	await get_tree().create_timer(DEMORA_MOSTRAR, true).timeout
	visible = true

func _on_reintentar_presionado() -> void:
	## Eliminar este nodo antes de la transición.
	## Fue añadido al root (no a la escena), por lo que no se destruye automáticamente
	## al cambiar de escena — hay que liberarlo manualmente.
	## El fade del SceneManager (capa 128) cubre la desaparición visualmente.
	queue_free()
	SceneManager.go_to_room(Constants.SCENE_SALA1)
