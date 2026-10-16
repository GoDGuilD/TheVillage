# File: SignPost.gd
# Description: Makes a sign tile readable - an invisible marker in the "talkable" group at the sign's cell that names its dialogue entry.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
class_name SignPost
extends Node2D
## The sign itself is a solid tile painted by AreaBuilder; this node only answers the talkable contract.

var text_key := ""


func setup(key: String) -> void:
	text_key = key


func _ready() -> void:
	add_to_group("talkable")


func talk_point() -> Vector2:
	return global_position


func talk(_from: Vector2) -> String:
	return text_key


func rest() -> void:
	pass
