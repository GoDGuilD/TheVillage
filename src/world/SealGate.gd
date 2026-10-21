# File: SealGate.gd
# Description: The gate of Caver's keep - a barred gate with three seal sockets; it opens for good once Joe holds all three family seals. Its crystal variant bars Caver's tower in the Dark World with four dimension sockets.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-19
# Last edit date: 2026-10-20
# Version: 1.1.0
class_name SealGate
extends StaticBody2D
## Talkable: the World sees a SealGate and either opens it (flag) or says how many seals are missing. The sockets
## light up for the seals Joe already has. With `crystal` set (setup's third argument) it is the tower's gate: four
## sockets, one per dimension crystal, each lit in its own colour (gen_tower.py).

const TEX := preload("res://assets/sprites/dungeon/seal_gate.png")
const SOCKET_TEX := preload("res://assets/sprites/dungeon/seal_socket.png")
const SIZE := Vector2(32, 32)
const LAYER_WORLD := 1
const SOCKETS := [Vector2(-8.5, -11.5), Vector2(-0.5, -11.5), Vector2(7.5, -11.5)]   # centred on the sockets
const CRYSTAL_TEX := preload("res://assets/sprites/dungeon/crystal_gate.png")
const CRYSTAL_SOCKET_DIR := "res://assets/sprites/dungeon/crystal_socket_%d.png"     # 0..3: Umbra..Silva
const CRYSTAL_SOCKETS := [Vector2(-8.5, -10.5), Vector2(-2.5, -10.5), Vector2(3.5, -10.5), Vector2(9.5, -10.5)]
const TALK_DROP := Vector2(0, 2)         # talk point: near the gate's lower edge (Joe stands in front of either half)

var flag := ""
var is_open := false
var crystal := false                     # the tower's crystal gate (else the keep's seal gate)

var _sprite: Sprite2D
var _shape: CollisionShape2D
var _sockets: Array[Sprite2D] = []


func setup(gate_flag: String, starts_open: bool, crystal_gate: bool = false) -> void:
	flag = gate_flag
	is_open = starts_open
	crystal = crystal_gate


func _ready() -> void:
	collision_layer = LAYER_WORLD
	collision_mask = 0
	add_to_group("talkable")
	_shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = SIZE
	_shape.shape = r
	add_child(_shape)
	_sprite = Sprite2D.new()
	_sprite.texture = CRYSTAL_TEX if crystal else TEX
	add_child(_sprite)
	var spots: Array = CRYSTAL_SOCKETS if crystal else SOCKETS
	for i in spots.size():
		var s := Sprite2D.new()
		s.texture = load(CRYSTAL_SOCKET_DIR % i) if crystal else SOCKET_TEX
		s.position = spots[i]
		_sprite.add_child(s)
		_sockets.append(s)
	refresh(0)
	_apply()


# Light one socket per seal held (the first `seals_held`), or - crystal gate - pass `which`, one bool per socket.
func refresh(seals_held: int, which: Array = []) -> void:
	for i in _sockets.size():
		_sockets[i].visible = bool(which[i]) if i < which.size() else i < seals_held


func lit_sockets() -> int:
	var n := 0
	for s in _sockets:
		n += int(s.visible)
	return n


func open_gate() -> void:
	if is_open:
		return
	is_open = true
	Audio.sfx("crystal_gate" if crystal else "shutter")
	Juice.shake(3.0, 0.4)
	remove_from_group("talkable")
	_apply()


func _apply() -> void:
	_sprite.visible = not is_open
	_shape.set_deferred("disabled", is_open)
	if is_open:
		remove_from_group("talkable")


func talk_point() -> Vector2:
	return global_position + TALK_DROP


func talk(_from: Vector2) -> String:
	return "crystal_gate" if crystal else "seal_gate"


func rest() -> void:
	pass
