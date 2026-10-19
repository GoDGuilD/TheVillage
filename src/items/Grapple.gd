# File: Grapple.gd
# Description: The grapple (ALttP's hookshot) - a claw on a chain shot straight ahead: it bites into hook posts and pulls Joe to them (over chasms and water), stuns enemies, and comes back from walls or the end of its chain.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-21
# Last edit date: 2026-10-21
# Version: 1.0.1
extends Node2D
## Flies over tiles flagged "low" (water, pits); stops at any other solid tile or body. Its HitBox has element "hook":
## ordinary enemies are stunned by it (like the boomerang); the Gloom Moth is dragged to the ground.

signal finished

const HEAD_TEX := preload("res://assets/sprites/items/grapple_head.png")
const CHAIN_TEX := preload("res://assets/sprites/items/chain.png")
const SPEED := 260.0
const RETURN_SPEED := 320.0
const RANGE := 112.0                     # seven tiles of chain
const HEIGHT := 9.0                      # flies at chest height (drawing only)
const LATCH_RADIUS := 10.0               # a hookable this close to the claw is caught
const STOP_SHORT := 16.0                 # Joe lands on the cell in front of the post...
const FEET_DROP := 6.0                   # ...with his feet where a cell's feet point is (cell centre + 6)
const LINK_STEP := 6.0                   # px between drawn chain links
const HOOK_ELEMENT := "hook"
const LAYER_WORLD := 1
const LAYER_PROPS := 128
const LAYER_PLAYER_HITBOX := 8

var direction := Vector2.RIGHT
var owner_node: Node2D                   # Joe
var state := "out"                       # out | back | latched
var target: Node2D = null                # the hookable it bit
var travelled := 0.0
var hit_box: HitBox

var _head: Sprite2D
var _links: Node2D


func _ready() -> void:
	add_to_group("grapple")
	z_index = 1                         # drawn above the actors it crosses
	_links = Node2D.new()
	add_child(_links)
	_head = Sprite2D.new()
	_head.texture = HEAD_TEX
	_head.rotation = direction.angle()
	add_child(_head)
	hit_box = HitBox.new()
	hit_box.collision_layer = LAYER_PLAYER_HITBOX
	hit_box.collision_mask = 0
	hit_box.damage = 0
	hit_box.element = HOOK_ELEMENT
	var s := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 5.0
	s.shape = c
	hit_box.add_child(s)
	add_child(hit_box)
	hit_box.set_active(true)
	hit_box.landed.connect(func(_hb: HurtBox) -> void:
		if state == "out":
			_retract())
	Audio.sfx("chain")


func _origin() -> Vector2:
	return owner_node.global_position + Vector2(0, -HEIGHT) if is_instance_valid(owner_node) else global_position


func _physics_process(delta: float) -> void:
	if not is_instance_valid(owner_node):
		queue_free()
		return
	match state:
		"out":
			var step := direction * SPEED * delta
			var next := global_position + step
			var hook := _hookable_near(next)
			if hook != null:
				_latch(hook)
				return
			if _blocked(next + Vector2(0, HEIGHT)):
				_retract()
				return
			global_position = next
			travelled += step.length()
			if travelled >= RANGE:
				_retract()
		"back":
			var to := _origin() - global_position
			if to.length() <= RETURN_SPEED * delta:
				_done()
				return
			global_position += to.normalized() * RETURN_SPEED * delta
		"latched":
			if is_instance_valid(target):
				global_position = target.call("hook_point") + Vector2(0, -HEIGHT) - direction * 4.0
	_draw_chain()


func _hookable_near(at: Vector2) -> Node2D:
	for h in get_tree().get_nodes_in_group("hookable"):
		var node := h as Node2D
		if node != null and (node.call("hook_point") + Vector2(0, -HEIGHT)).distance_to(at) <= LATCH_RADIUS:
			return node
	return null


# True if the claw at `ground` (its ground point) would hit a wall: a solid tile that is not "low", or a body.
func _blocked(ground: Vector2) -> bool:
	var q := PhysicsPointQueryParameters2D.new()
	q.position = ground
	q.collision_mask = LAYER_WORLD | LAYER_PROPS
	for hit in get_world_2d().direct_space_state.intersect_point(q, 8):
		var col: Object = hit["collider"]
		if col is TileMapLayer:
			var tl := col as TileMapLayer
			var td := tl.get_cell_tile_data(tl.local_to_map(tl.to_local(ground)))
			if td != null and not bool(td.get_custom_data("low")):
				return true
		elif col != owner_node:
			return true
	return false


func _latch(hook: Node2D) -> void:
	state = "latched"
	target = hook
	hit_box.set_active(false)
	Audio.sfx("clink")
	var point: Vector2 = hook.call("hook_point") - direction * STOP_SHORT + Vector2(0, FEET_DROP)
	owner_node.call("grapple_pull", point, self)


func _retract() -> void:
	state = "back"
	hit_box.set_active(false)


func _done() -> void:
	finished.emit()
	queue_free()


# Called by Joe when the pull has brought him to the post.
func release() -> void:
	_done()


func _draw_chain() -> void:
	for c in _links.get_children():
		c.queue_free()
	var from := _origin()
	var to := global_position
	var n := int(from.distance_to(to) / LINK_STEP)
	for i in range(1, n):
		var link := Sprite2D.new()
		link.texture = CHAIN_TEX
		link.position = from.lerp(to, float(i) / n) - global_position
		_links.add_child(link)
