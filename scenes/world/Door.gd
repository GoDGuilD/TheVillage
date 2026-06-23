extends Area2D
## Door: transition trigger between rooms.
## When the player enters the area, it calls SceneManager.go_to_room().
##
## Inspector configuration (@export properties):
##   target_scene — res:// path of the destination room
##   spawn_id     — id of the spawn point in the destination room ("norte", "sur", etc.)
##
## Example: Sala1's north door → target_scene=Sala2, spawn_id="sur"
## (the player appears at the south of Sala2, as if having entered from above)

## Path of the scene this door leads to.
@export var target_scene: String = ""

## ID of the spawn point in the destination room.
## Must match a child node of PuntosSpawn named "Spawn" + spawn_id.capitalize().
@export var spawn_id: String = ""

func _ready() -> void:
	## Detect when a physics body enters the area (the player's CharacterBody2D).
	body_entered.connect(_on_body_entered)
	## Draw the yellow visual indicator once on init.
	queue_redraw()

func _draw() -> void:
	## Visual indicator: 32×8 px yellow stripe centered on the node.
	## Shows up in-game as a flash at the room's edge.
	## Replace with a real sprite once assets exist.
	draw_rect(Rect2(-16.0, -4.0, 32.0, 8.0), Color(1.0, 0.85, 0.0, 0.9))

func _on_body_entered(body: Node) -> void:
	## Only the player triggers the door (compare class, not name).
	if not body is Player:
		return
	if target_scene.is_empty():
		push_warning("Door: target_scene not configured on '%s'." % name)
		return
	## SceneManager handles the fade, the scene change and the player's spawn.
	SceneManager.go_to_room(target_scene, spawn_id)
