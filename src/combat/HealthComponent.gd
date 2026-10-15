# File: HealthComponent.gd
# Description: Reusable hit-point pool (ported from The Village); emits signals instead of touching its owner.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-12
# Last edit date: 2026-10-12
# Version: 1.0.0
class_name HealthComponent
extends Node

signal health_changed(current: int, maximum: int)
signal died

@export var max_health: int = 30

var current_health: int


func _ready() -> void:
	current_health = max_health


func take_damage(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = maxi(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		died.emit()


func heal(amount: int) -> void:
	current_health = mini(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)


func is_alive() -> bool:
	return current_health > 0
