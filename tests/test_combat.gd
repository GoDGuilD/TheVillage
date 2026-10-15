# File: test_combat.gd
# Description: Headless scripted checks for Phase 2: spin attack, shield, enemies (slime/guard/spitter), hit-stop, drops and pickups, lift/carry/throw, HUD, death and respawn.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-15
# Last edit date: 2026-10-15
# Version: 1.0.0
# Run:  Godot_console --headless --fixed-fps 60 --path . -s tests/test_combat.gd   (must end "0 failed")
extends SceneTree
## Autoloads and the classes that use them are reached at runtime only (root.get_node / load), never by
## static type names: an -s script is compiled before the autoload singletons exist (Chapel of Dreams lesson).

const FIELD_SCENE := "res://src/world/TestField.tscn"
const SLIME := "res://src/enemies/Slime.gd"
const GUARD := "res://src/enemies/Guard.gd"
const SPITTER := "res://src/enemies/Spitter.gd"
const ROCK := "res://src/enemies/EnemyRock.gd"
const PICKUP := "res://src/world/Pickup.gd"
const FPS := 60.0
const ARENA := [
	"RRRRRRRRRRRRRRRRRRRRRRRR",
	"R......................R",
	"R......................R",
	"R......................R",
	"R......................R",
	"R......................R",
	"R.....P................R",
	"R......................R",
	"R......................R",
	"R......................R",
	"R.....O.........B......R",
	"R......................R",
	"R..............O.......R",
	"RRRRRRRRRRRRRRRRRRRRRRRR",
]

var _field: Node2D
var _p
var _gs: Node
var _audio: Node
var _juice: Node
var _passed := 0
var _failed := 0


func _initialize() -> void:
	_gs = root.get_node("GameState")
	_audio = root.get_node("Audio")
	_juice = root.get_node("Juice")
	_gs.reset()
	_gs.drops_enabled = false
	_field = load(FIELD_SCENE).instantiate()
	_field.layout = ARENA
	root.add_child(_field)
	await process_frame
	_p = _field.player
	await _run_all()


func _run_all() -> void:
	await _t_charge_and_spin()
	await _t_early_release()
	await _t_charge_walk()
	await _t_spin_kills_around()
	await _t_slash_guard_knockback_hitstop()
	await _t_guard_dies_and_drops()
	await _t_heart_pickup()
	await _t_shield_blocks_front()
	await _t_rock_from_behind_hurts()
	await _t_rock_while_slashing_hurts()
	await _t_contact_damage()
	await _t_lift_carry_throw_pot()
	await _t_thrown_pot_hits_enemy()
	await _t_lift_bush()
	await _t_hit_drops_carried()
	await _t_spitter_spits()
	await _t_guard_chases()
	await _t_hud()
	await _t_death_and_respawn()
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


func _secs(s: float) -> void:
	await _frames(int(ceil(s * FPS)))


func _tap(action: String) -> void:
	Input.action_press(action)
	await _frames(2)
	Input.action_release(action)


func _state() -> String:
	return _p.fsm.current_state


# Clear inputs and leftovers, heal Joe, and stand him at (x, y) facing `facing`.
func _reset(x: float, y: float, facing: Vector2i = Vector2i.DOWN) -> void:
	for a in ["attack", "interact"]:
		Input.action_release(a)
	_p._input_override = Vector2.ZERO
	_p.revive(Vector2(x, y))
	_p.facing = facing
	_p._iframes_left = 0.0
	_p.fsm.transition_to("idle")
	_gs.force_drop = ""
	for e in _field.enemies:
		if is_instance_valid(e):
			e.queue_free()
	_field.enemies.clear()
	for n in _field.actors.get_children():
		var sc = n.get_script()
		if sc != null and (sc.resource_path == ROCK or sc.resource_path == PICKUP):
			n.queue_free()
	await _frames(4)


# Add an enemy that holds still (no player to see, AI timers parked) unless `alive` is true.
func _enemy(path: String, pos: Vector2, alive: bool = false):
	var e = load(path).new()
	e.position = pos
	_field.actors.add_child(e)
	_field.enemies.append(e)
	if alive:
		e.player = _p
	else:
		_park(e)
	return e


func _park(e) -> void:
	var path: String = e.get_script().resource_path
	if path == SLIME:
		e._rest_left = 999.0
	elif path == GUARD:
		e._pause_left = 999.0
	elif path == SPITTER:
		e._recover_left = 999.0


func _rock(pos: Vector2, dir: Vector2):
	var r = load(ROCK).new()
	r.direction = dir
	r.position = pos
	_field.actors.add_child(r)
	return r


func _count_script(path: String) -> int:
	var n := 0
	for c in _field.actors.get_children():
		var sc = c.get_script()
		if sc != null and sc.resource_path == path and not c.is_queued_for_deletion():
			n += 1
	return n


# --- spin attack --------------------------------------------------------------

func _t_charge_and_spin() -> void:
	await _reset(200, 110)
	Input.action_press("attack")
	await _frames(20)                            # the slash ends, the button is still held
	_check("holding after a slash charges", _state() == "charge", _state())
	_check("not charged yet", not _p.charged)
	await _secs(0.85)
	_check("charged after CHARGE_TIME", _p.charged)
	_check("charge sound played", _audio.played_recently("charge_ready"))
	Input.action_release("attack")
	await _frames(2)
	_check("release spins", _state() == "spin", _state())
	_check("spin box is live", _p.spin_box.monitorable)
	_check("spin sound played", _audio.played_recently("sword_spin"))
	await _secs(0.4)
	_check("spin ends in idle", _state() == "idle", _state())
	_check("spin box off afterwards", not _p.spin_box.monitorable)


func _t_early_release() -> void:
	await _reset(200, 110)
	Input.action_press("attack")
	await _frames(24)
	Input.action_release("attack")
	await _frames(3)
	_check("early release does not spin", _state() == "idle", _state())


func _t_charge_walk() -> void:
	await _reset(200, 110, Vector2i.DOWN)
	Input.action_press("attack")
	await _frames(20)
	var x0: float = _p.global_position.x
	_p._input_override = Vector2.LEFT
	await _frames(30)
	var dx: float = x0 - _p.global_position.x
	_check("shuffles at half speed while charging", absf(dx - 45.0 * 30.0 / FPS) <= 3.0, "dx=%.1f" % dx)
	_check("facing stays locked while charging", _p.facing == Vector2i.DOWN, str(_p.facing))
	_p._input_override = Vector2.ZERO
	Input.action_release("attack")
	await _frames(3)


func _t_spin_kills_around() -> void:
	await _reset(200, 110, Vector2i.DOWN)
	var behind = _enemy(SLIME, Vector2(200, 92))       # north of Joe: a slash facing down cannot reach it
	var side = _enemy(SLIME, Vector2(220, 110))
	Input.action_press("attack")
	await _frames(20)
	await _secs(0.85)
	Input.action_release("attack")
	await _secs(0.45)
	_check("spin hits the enemy behind Joe", not is_instance_valid(behind) or behind.is_dead())
	_check("spin hits the enemy at his side", not is_instance_valid(side) or side.is_dead())


# --- enemies ------------------------------------------------------------------

func _t_slash_guard_knockback_hitstop() -> void:
	await _reset(200, 100, Vector2i.DOWN)
	var g = _enemy(GUARD, Vector2(200, 122))
	await _frames(3)
	var y0: float = g.global_position.y
	_juice.last_hit_stop = 0.0
	await _tap("attack")
	await _frames(4)
	_check("slash costs the guard 2 HP", g.health.current_health == 4, str(g.health.current_health))
	_check("hit-stop was applied", _juice.last_hit_stop > 0.0)
	await _frames(12)
	_check("guard knocked back away from Joe", g.global_position.y - y0 > 8.0, "dy=%.1f" % (g.global_position.y - y0))
	_check("enemy hit sound", _audio.played_recently("enemy_hit", 20))


func _t_guard_dies_and_drops() -> void:
	await _reset(200, 100, Vector2i.DOWN)
	_gs.force_drop = "gem_blue"
	var g = _enemy(GUARD, Vector2(200, 120))
	var fx0: int = _juice.fx_count
	for i in 3:
		g.global_position = Vector2(200, 120)          # put it back in reach after each knockback
		await _tap("attack")
		await _frames(24)
	_check("three slashes defeat the guard", not is_instance_valid(g))
	_check("death puff played", _juice.fx_count > fx0)
	_check("a gem dropped", _count_script(PICKUP) == 1, str(_count_script(PICKUP)))
	var gems0: int = _gs.gems
	_p._input_override = Vector2.DOWN
	await _frames(20)
	_p._input_override = Vector2.ZERO
	_check("walking over the blue gem adds 5", _gs.gems == gems0 + 5, "%d -> %d" % [gems0, _gs.gems])
	_check("gem sound", _audio.played_recently("pickup_gem", 20))


func _t_heart_pickup() -> void:
	await _reset(200, 110)
	_p.health.take_damage(4)
	var h = load(PICKUP).new()
	h.kind = "heart"
	h.position = Vector2(200, 106)
	_field.actors.add_child(h)
	await _frames(12)
	_check("a heart heals one heart", _p.health.current_health == 4, str(_p.health.current_health))


# --- shield -------------------------------------------------------------------

func _t_shield_blocks_front() -> void:
	await _reset(200, 80, Vector2i.DOWN)
	var r = _rock(Vector2(200, 120), Vector2.UP)       # coming at Joe's face
	await _frames(30)
	_check("shield blocks a rock from the front", _p.health.current_health == 6, str(_p.health.current_health))
	_check("block sound", _audio.played_recently("shield_block", 20))
	_check("blocked rock is deflected", not is_instance_valid(r) or r.deflected)


func _t_rock_from_behind_hurts() -> void:
	await _reset(200, 110, Vector2i.DOWN)
	_rock(Vector2(200, 50), Vector2.DOWN)               # hits his back
	await _frames(40)
	_check("a rock from behind hurts", _p.health.current_health == 4, str(_p.health.current_health))


func _t_rock_while_slashing_hurts() -> void:
	await _reset(200, 80, Vector2i.DOWN)
	_rock(Vector2(200, 104), Vector2.UP)
	Input.action_press("attack")
	await _frames(12)
	Input.action_release("attack")
	await _frames(10)
	_check("no shield while swinging", _p.health.current_health == 4, str(_p.health.current_health))


func _t_contact_damage() -> void:
	await _reset(200, 110)
	_enemy(SLIME, Vector2(200, 112))
	await _frames(6)
	_check("touching an enemy hurts", _p.health.current_health == 4, str(_p.health.current_health))
	_check("hurt sound", _audio.played_recently("hurt", 20))


# --- lift and throw -------------------------------------------------------------

func _t_lift_carry_throw_pot() -> void:
	var pot = _field.pots[0]                            # cell (6,10): centre (104,168)
	await _reset(104, 160, Vector2i.DOWN)
	_check("the pot is in reach", _p.liftable_in_front() == pot)
	await _tap("interact")
	_check("interact lifts", _state() == "lift", _state())
	await _frames(16)
	_check("then carries", _state() == "carry" and _p.carrying == "pot", _state())
	_check("the pot left the ground", not is_instance_valid(pot))
	_p._input_override = Vector2.UP
	await _frames(10)
	_p._input_override = Vector2.ZERO
	_check("walks while carrying", _p.facing == Vector2i.UP and _p.global_position.y < 155.0)
	_gs.force_drop = "heart"
	await _tap("interact")
	_check("interact again throws", _state() == "throw", _state())
	await _frames(30)
	_check("the pot shattered", _audio.played_recently("shatter", 30))
	_check("a broken pot can drop items", _count_script(PICKUP) >= 1)
	_check("hands are empty again", _p.carrying == "" and _state() == "idle", _state())


func _t_thrown_pot_hits_enemy() -> void:
	var pot = _field.pots[1]                            # cell (15,12): centre (248,200)
	await _reset(248, 192, Vector2i.DOWN)
	await _tap("interact")
	await _frames(16)
	_p.facing = Vector2i.RIGHT
	var s = _enemy(SLIME, Vector2(288, 192))
	await _tap("attack")                                # the sword button throws too
	await _frames(25)
	_check("a thrown pot kills a slime", not is_instance_valid(s) or s.is_dead())
	_check("pot was lifted from its spot", not is_instance_valid(pot))


func _t_lift_bush() -> void:
	await _reset(264, 156, Vector2i.DOWN)               # bush at cell (16,10): centre (264,168)
	await _tap("interact")
	await _frames(16)
	_check("bushes can be lifted", _p.carrying == "bush", _p.carrying)
	await _tap("interact")
	await _frames(30)


func _t_hit_drops_carried() -> void:
	await _reset(200, 110)
	var p = load("res://src/world/Pot.gd").new()
	p.position = Vector2(200, 124)
	_field.actors.add_child(p)
	await _frames(2)
	await _tap("interact")
	await _frames(16)
	_check("carrying a fresh pot", _p.carrying == "pot")
	_p._on_hurt(2, _p.global_position + Vector2(0, 20), Vector2.ZERO)
	_check("a hit makes Joe drop it", _p.carrying == "" and _state() == "hurt", _state())
	await _frames(30)


func _t_spitter_spits() -> void:
	await _reset(60, 60)
	var sp = _enemy(SPITTER, Vector2(300, 150))
	sp.facing = Vector2i.LEFT
	var rocks0 := _count_script(ROCK)
	sp.spit()
	await _frames(2)
	_check("the spitter fires a rock", _count_script(ROCK) == rocks0 + 1)
	_check("spit sound", _audio.played_recently("spit", 20))
	var rock = null
	for c in _field.actors.get_children():
		var sc = c.get_script()
		if sc != null and sc.resource_path == ROCK:
			rock = c
	var x0: float = rock.global_position.x
	await _frames(10)
	_check("the rock flies along the spitter's facing", rock.global_position.x < x0 - 10.0)


func _t_guard_chases() -> void:
	await _reset(100, 110)
	var g = _enemy(GUARD, Vector2(170, 110), true)
	var d0: float = g.global_position.distance_to(_p.global_position)
	await _frames(40)
	_check("a guard that sees Joe chases him", g.chasing and g.global_position.distance_to(_p.global_position) < d0 - 15.0,
			"d %.0f -> %.0f" % [d0, g.global_position.distance_to(_p.global_position)])


# --- HUD, death ------------------------------------------------------------------

func _t_hud() -> void:
	await _reset(200, 110)
	_check("HUD shows three full hearts", _field.hud.hearts_shown == "FFF", _field.hud.hearts_shown)
	_p.health.take_damage(3)
	_check("HUD shows half hearts", _field.hud.hearts_shown == "FHE", _field.hud.hearts_shown)
	_gs.add_gems(7)
	_check("HUD gem counter follows GameState", _field.hud.gems_shown == _gs.gems, str(_field.hud.gems_shown))


func _t_death_and_respawn() -> void:
	await _reset(200, 110)
	var deaths0: int = _field.deaths
	_p._on_hurt(99, _p.global_position + Vector2(0, -20), Vector2.ZERO)
	await _frames(2)
	_check("Joe falls at zero health", _state() == "dead", _state())
	_check("death sound", _audio.played_recently("player_die", 20))
	await _secs(1.7)
	_check("he gets back up at the spawn", _state() == "idle" and _p.global_position == _field.spawn_point
			and _field.deaths == deaths0 + 1, _state())
	_check("with full hearts", _p.health.current_health == 6)
