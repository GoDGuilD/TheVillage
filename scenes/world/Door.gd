extends Area2D
## Puerta: trigger de transición entre salas.
## Cuando el jugador entra en el área, llama a SceneManager.go_to_room().
##
## Configuración en el inspector (propiedades @export):
##   target_scene — ruta res:// de la sala destino
##   spawn_id     — id del punto de spawn en la sala destino ("norte", "sur", etc.)
##
## Ejemplo: puerta norte de Sala1 → target_scene=Sala2, spawn_id="sur"
## (el jugador aparece en el sur de Sala2, como si hubiera entrado por arriba)

## Ruta de la escena a la que lleva esta puerta.
@export var target_scene: String = ""

## ID del punto de spawn en la sala destino.
## Debe coincidir con un nodo hijo de PuntosSpawn llamado "Spawn" + spawn_id.capitalize().
@export var spawn_id: String = ""

func _ready() -> void:
	## Detectar cuando un cuerpo físico entra en el área (CharacterBody2D del jugador).
	body_entered.connect(_on_body_entered)
	## Dibujar el indicador visual amarillo una vez al inicializar.
	queue_redraw()

func _draw() -> void:
	## Indicador visual: franja amarilla de 32×8 px centrada en el nodo.
	## Se verá en el juego como un destello en el borde de la sala.
	## Reemplazar con un sprite real cuando haya assets.
	draw_rect(Rect2(-16.0, -4.0, 32.0, 8.0), Color(1.0, 0.85, 0.0, 0.9))

func _on_body_entered(body: Node) -> void:
	## Solo el jugador activa la puerta (comparar clase, no nombre).
	if not body is Player:
		return
	if target_scene.is_empty():
		push_warning("Door: target_scene no configurado en '%s'." % name)
		return
	## SceneManager maneja el fade, el cambio de escena y el spawn del jugador.
	SceneManager.go_to_room(target_scene, spawn_id)
