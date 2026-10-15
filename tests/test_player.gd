# File: test_player.gd
# Description: Headless scripted checks for top-down Joe: walking, ALttP facing rules, walls, corner nudge, sword slash, bushes, damage.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
# Run:  Godot_console --headless --fixed-fps 60 --path . -s tests/test_player.gd   (must end "0 failed")
extends SceneTree

const FIELD_SCENE := "res://src/world/TestField.tscn"
const TILE := 16
const FPS := 60.0
const SPEED := 90.0                       # mirrors PlayerTuning.WALK_SPEED
const TOL := 3.0                          # px tolerance on distances
# Small walled arena: rock border, one lone rock for corner tests, two bushes.
const ARENA := [
	"RRRRRRRRRRRRRRRRRRRRRRRR",
	"R......................R",
	"R......................R",
	"R......................R",
	"R...........R..........R",
	"R......................R",
	"R.....P................R",
	"R......................R",
	"R......................R",
	"R......................R",
	"R.....B.........B......R",
	"R......................R",
	"R......................R",
	"RRRRRRRRRRRRRRRRRRRRRRRR",
]

var _field: Node2D
var _p                                    # untyped: Player instance
var _passed := 0
var _failed := 0


func _initialize() -> void:
	_field = load(FIELD_SCENE).instantiate()
	_field.layout = ARENA
	root.add_child(_field)
	await process_frame
	_p = _field.player
	await _run_all()


func _run_all() -> void:
	await _t_idle()
	await _t_walk_right_left()
	await _t_diagonal_speed()
	await _t_facing_rules()
	await _t_wall_blocks()
	await _t_corner_nudge()
	await _t_attack()
	await _t_attack_chain()
	await _t_bush_blocks_and_cuts()
	await _t_hurt_and_iframes()
	await _t_default_field()
	print("\nRESULT: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


# --- helpers -----------------------------------------------------------------

func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_passed += 1
		print("  PASS  ", name, "  ", detail)
	else:
		_failed += 1
		print("  FAIL  ", name, "  ", detail)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _tap(action: String) -> void:
	Input.action_press(action)
	await _frames(1)
	Input.action_release(action)


func _state() -> String:
	return _p.fsm.current_state


# Put Joe's feet at (x, y), facing down, no input, and let him settle.
func _reset(x: float, y: float, facing: Vector2i = Vector2i.DOWN) -> void:
	_p._input_override = Vector2.ZERO
	Input.action_release("attack")
	_p.global_position = Vector2(x, y)
	_p.velocity = Vector2.ZERO
	_p.facing = facing
	_p.fsm.transition_to("idle")
	await _frames(4)


func _hold(dir: Vector2, frames: int) -> void:
	_p._input_override = dir
	await _frames(frames)
	_p._input_override = Vector2.ZERO


# --- tests -------------------------------------------------------------------

func _t_idle() -> void:
	await _reset(104, 110)
	_check("starts idle", _state() == "idle", _state())
	_check("idle animation faces down", _p.sprite.animation == "idle_down", _p.sprite.animation)
	_check("full health", _p.health.current_health == 6, str(_p.health.current_health))


func _t_walk_right_left() -> void:
	await _reset(104, 110)
	var x0: float = _p.global_position.x
	await _hold(Vector2.RIGHT, 30)
	var dx: float = _p.global_position.x - x0
	_check("walks right at full speed instantly", absf(dx - SPEED * 30.0 / FPS) <= TOL, "dx=%.1f" % dx)
	_check("faces right", _p.facing == Vector2i.RIGHT, str(_p.facing))
	_check("side walk animation, not mirrored", _p.sprite.animation == "walk_side" and not _p.sprite.flip_h)
	await _frames(2)
	_check("stops dead on release", _state() == "idle" and _p.velocity == Vector2.ZERO, _state())
	await _hold(Vector2.LEFT, 10)
	_check("walking left mirrors the side strip", _p.sprite.flip_h and _p.facing == Vector2i.LEFT)


func _t_diagonal_speed() -> void:
	await _reset(104, 110)
	var start: Vector2 = _p.global_position
	await _hold(Vector2(1, 1).normalized(), 30)
	var d: float = _p.global_position.distance_to(start)
	_check("diagonals are normalised", absf(d - SPEED * 30.0 / FPS) <= TOL, "d=%.1f" % d)


func _t_facing_rules() -> void:
	await _reset(104, 110, Vector2i.DOWN)
	await _hold(Vector2(1, 1).normalized(), 6)
	_check("diagonal keeps a facing that is still held", _p.facing == Vector2i.DOWN, str(_p.facing))
	await _reset(104, 110, Vector2i.RIGHT)
	await _hold(Vector2.UP, 3)
	_check("turning to a new axis faces it", _p.facing == Vector2i.UP, str(_p.facing))
	await _reset(104, 110, Vector2i.LEFT)
	await _hold(Vector2(1, -1).normalized(), 3)
	_check("from a dropped facing, a perfect diagonal faces vertically", _p.facing == Vector2i.UP, str(_p.facing))


func _t_wall_blocks() -> void:
	await _reset(104, 60)
	await _hold(Vector2.UP, 90)
	var y: float = _p.global_position.y
	# The border rock row ends at y=16; the 6-px feet box stops the feet at y=22.
	_check("rock wall stops Joe", y >= 2 * TILE - 10.0 - 0.5 and y <= 2 * TILE - 10.0 + 1.5, "y=%.1f" % y)


func _t_corner_nudge() -> void:
	# Lone rock at cell (12,4): x 192..208, y 64..80. Feet box is 10 px wide.
	await _reset(192 - 5 + 4, 110)                # box overlaps the rock by 4 px on its left edge
	await _hold(Vector2.UP, 90)
	var p: Vector2 = _p.global_position
	_check("corner nudge slides Joe around a rock edge", p.y < 60.0 and p.x <= 187.5, "pos=%s" % p)
	await _reset(200, 110)                        # dead centre under the rock: no nudge
	await _hold(Vector2.UP, 60)
	p = _p.global_position
	_check("no nudge when walking straight into the middle", p.y >= 85.0 and absf(p.x - 200.0) < 0.5, "pos=%s" % p)


func _t_attack() -> void:
	await _reset(104, 110)
	_p._input_override = Vector2.ZERO
	Input.action_press("attack")
	await _frames(2)                            # a press is seen on the next physics frame
	Input.action_release("attack")
	_check("attack state on press", _state() == "attack", _state())
	_check("attack animation for the facing", _p.sprite.animation == "attack_down", _p.sprite.animation)
	var was_live := false
	for i in 16:
		if _p.sword.monitorable:
			was_live = true
		_p._input_override = Vector2.RIGHT          # holding a direction must not move Joe mid-slash
		await _frames(1)
	_p._input_override = Vector2.ZERO
	_check("sword box is live during the hit window", was_live)
	await _frames(6)
	_check("slash ends back in idle", _state() == "idle", _state())
	_check("sword box is off after the slash", not _p.sword.monitorable)


func _t_attack_chain() -> void:
	await _reset(104, 110)
	await _tap("attack")
	await _frames(8)
	await _tap("attack")                       # buffered near the end of the first slash
	await _frames(10)
	_check("a buffered press chains a second slash", _state() == "attack", _state())
	await _frames(20)
	_check("chain finishes in idle", _state() == "idle", _state())


func _t_bush_blocks_and_cuts() -> void:
	var b1 = _field.bushes[0]                     # cell (6,10): centre (104,168)
	var b2 = _field.bushes[1]                     # cell (16,10): centre (264,168)
	await _reset(264, 140)
	await _hold(Vector2.DOWN, 40)
	var y: float = _p.global_position.y
	_check("an uncut bush blocks walking", y <= 163.5 and is_instance_valid(b2), "y=%.1f" % y)
	await _reset(104, 158, Vector2i.DOWN)
	await _tap("attack")
	var saw_leaves := false
	for i in 16:
		await _frames(1)
		for n in _field.actors.get_children():
			if n is AnimatedSprite2D and n.is_playing() and n.animation == "burst":
				saw_leaves = true
	_check("the slash cuts the bush in front", not is_instance_valid(b1))
	_check("a cut bush leaves a playing leaf burst", saw_leaves)
	_check("the other bush is untouched", is_instance_valid(b2))
	await _reset(104, 140)
	await _hold(Vector2.DOWN, 40)
	_check("a cut bush no longer blocks", _p.global_position.y > 175.0, "y=%.1f" % _p.global_position.y)


func _t_hurt_and_iframes() -> void:
	await _reset(104, 110, Vector2i.DOWN)
	var x0: float = _p.global_position.x
	_p._on_hurt(2, _p.global_position + Vector2(-20, -9), Vector2.ZERO)
	_check("a hit costs health", _p.health.current_health == 4, str(_p.health.current_health))
	_check("hurt state", _state() == "hurt", _state())
	_p._on_hurt(2, _p.global_position + Vector2(-20, -9), Vector2.ZERO)
	_check("invincible right after a hit", _p.health.current_health == 4)
	await _frames(14)
	_check("knocked away from the attacker", _p.global_position.x - x0 > 20.0, "dx=%.1f" % (_p.global_position.x - x0))
	_check("control returns after the stun", _state() == "idle", _state())
	await _frames(int(FPS * 1.0))
	_check("invincibility wears off", not _p.is_invincible() and _p.sprite.visible)
	_p.health.heal(99)


# The real meadow builds without errors and spawns Joe on the path crossing.
func _t_default_field() -> void:
	var f: Node2D = load(FIELD_SCENE).instantiate()
	root.add_child(f)
	await process_frame
	_check("default field spawns Joe", f.player != null)
	_check("default field has bushes", f.bushes.size() == 16, str(f.bushes.size()))
	_check("field is 2x2 screens", f.field_size() == Vector2i(768, 448), str(f.field_size()))
	f.queue_free()
	await process_frame
