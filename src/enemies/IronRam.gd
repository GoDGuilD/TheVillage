# File: IronRam.gd
# Description: Boss of Ram's Hollow - an armoured ram that lines up with Joe, lowers its head and charges along the line; hitting a wall leaves it dazed, and only then can it be hurt.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-19
# Last edit date: 2026-10-19
# Version: 1.0.0
class_name IronRam
extends BaseEnemy
## ALttP pattern: dodge the charge so it hits the wall, then punish while it reels. Sword hits on its armour clank.

const WALK_SPEED := 32.0
const CHARGE_SPEED := 200.0
const ALIGN := 14.0                      # px off-axis that still counts as "lined up"
const WINDUP := 0.55
const DAZE_TIME := 2.2
const CHARGE_DAMAGE := 4
const WALK_DAMAGE := 2
const MAX_CHARGE := 3.0                  # s: a charge that never meets a wall ends anyway

var is_boss := true
var state := "walk"                      # walk | windup | charge | dazed
var charges := 0

var _timer := 0.0
var _charge_dir := Vector2.ZERO


func _init() -> void:
	pack = "iron_ram"
	max_hp = 12
	contact_damage = WALK_DAMAGE
	directional = true
	body_size = Vector2(28, 18)
	body_center = Vector2(0, -12)
	stun_immune = true


func _anim_base() -> String:
	return "walk"


func is_dazed() -> bool:
	return state == "dazed"


# Armour: only a dazed ram can be hurt.
func _resists(_hit: HitBox) -> bool:
	return not is_dazed()


func _think(delta: float) -> void:
	match state:
		"walk":
			var to := _to_player()
			if to == Vector2.INF:
				_move(Vector2.ZERO)
				return
			if absf(to.x) <= ALIGN or absf(to.y) <= ALIGN:
				state = "windup"
				_timer = WINDUP
				_charge_dir = Vector2(signf(to.x), 0) if absf(to.y) <= ALIGN else Vector2(0, signf(to.y))
				_face(_charge_dir)
				_move(Vector2.ZERO)
				Audio.sfx("charge_ready", 0.6)
				return
			# Step along the shorter axis to line up.
			var step := Vector2(signf(to.x), 0) if absf(to.x) < absf(to.y) else Vector2(0, signf(to.y))
			_face(step)
			_play("walk")
			_move(step * WALK_SPEED)
		"windup":
			_timer -= delta
			_play("walk")
			if _timer <= 0.0:
				state = "charge"
				_timer = MAX_CHARGE
				charges += 1
				contact.damage = CHARGE_DAMAGE
				_play("charge")
		"charge":
			_timer -= delta
			_move(_charge_dir * CHARGE_SPEED)
			if get_slide_collision_count() > 0 or _timer <= 0.0:
				state = "dazed"
				_timer = DAZE_TIME
				contact.damage = WALK_DAMAGE
				Audio.sfx("bonk")
				Juice.shake(3.0, 0.3)
				sprite.play("dazed")
		"dazed":
			_move(Vector2.ZERO)
			_timer -= delta
			if _timer <= 0.0:
				state = "walk"
