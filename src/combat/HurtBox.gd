# File: HurtBox.gd
# Description: Area that RECEIVES damage; emits `hurt` with damage, the attacker's position and knockback when a HitBox overlaps it.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-12
# Last edit date: 2026-10-12
# Version: 1.1.0
class_name HurtBox
extends Area2D
## Layers: PlayerHurtBox = 6, EnemyHurtBox = 7. Set `collision_mask` to the opposing HitBox layer.

signal hurt(damage: int, source_position: Vector2, knockback: Vector2)

# The HitBox behind the `hurt` signal being emitted (handlers read its element, then clear this).
var last_hit: HitBox


func _ready() -> void:
	monitorable = false          # nothing needs to detect a hurt box
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	_receive(area)


# Re-apply any HitBox still overlapping (e.g. when invincibility ends while touching an enemy).
func recheck() -> void:
	for area in get_overlapping_areas():
		if area is HitBox:
			_receive(area)
			return


func _receive(area: Area2D) -> void:
	if not area is HitBox:
		return
	var box := area as HitBox
	last_hit = box
	hurt.emit(box.damage, box.global_position, box.knockback)
	box.landed.emit(self)
