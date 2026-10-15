# File: HitBox.gd
# Description: Area that DEALS damage (sword swings, enemy contact/attacks); the target's HurtBox detects it and reads damage + knockback.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-12
# Last edit date: 2026-10-12
# Version: 1.1.0
class_name HitBox
extends Area2D
## Detects nothing itself (monitoring is off). It is only found by HurtBoxes whose mask matches this layer.
## Layers: PlayerHitBox = 4 (value 8), EnemyHitBox = 5 (value 16).

# Emitted by a HurtBox when this box connected with it (used for hit-stop / shake on the attacker's side).
signal landed(hurt_box: HurtBox)

@export var damage: int = 1
# x = horizontal push (direction is computed away from this box), y = upward pop.
@export var knockback: Vector2 = Vector2(60.0, 80.0)
# "" (physical), "fire", "frost", "lightning" or "holy": decides weakness/resistance and status effects.
@export var element: String = ""


func _ready() -> void:
	monitoring = false


# A HitBox only hurts while monitorable; swings toggle it on/off so each swing re-triggers area_entered.
func set_active(on: bool) -> void:
	set_deferred("monitorable", on)
