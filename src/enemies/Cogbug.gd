# File: Cogbug.gd
# Description: The cogbug - a clockwork beetle of Tempus whose brass shell turns every blade; the Hammer flips it on its back, and only then can it be struck.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-23
# Last edit date: 2026-10-23
# Version: 1.0.0
class_name Cogbug
extends BaseEnemy
## Walks straight and turns clockwise when it bumps into something. A hammer hit flips it for FLIP_TIME s (no
## contact damage, every hit lands); then it rights itself.

const WALK_SPEED := 34.0
const FLIP_TIME := 3.5
const TURN := [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]

var flipped := false
var flips := 0
var _dir := 0
var _flip_left := 0.0


func _init() -> void:
	pack = "cogbug"
	max_hp = 4
	contact_damage = 2
	body_size = Vector2(14, 12)
	body_center = Vector2(0, -8)


func _anim_base() -> String:
	return "walk"


func _resists(_hit: HitBox) -> bool:
	return not flipped


func _on_hurt(damage: int, source_position: Vector2, knockback: Vector2) -> void:
	var hit := hurt_box.last_hit
	if not flipped and hit != null and hit.element == "hammer" and not is_dead():
		_iframes_left = IFRAMES
		flipped = true
		flips += 1
		_flip_left = FLIP_TIME
		contact.set_active(false)
		_play("flipped")
		Audio.sfx("clank")
		return
	super._on_hurt(damage, source_position, knockback)


func _think(delta: float) -> void:
	if flipped:
		_move(Vector2.ZERO)
		_flip_left -= delta
		if _flip_left <= 0.0:
			flipped = false
			contact.set_active(true)
			_play("walk")
		return
	var step := Vector2(TURN[_dir])
	_move(step * WALK_SPEED)
	if get_slide_collision_count() > 0:
		_dir = (_dir + 1) % TURN.size()
