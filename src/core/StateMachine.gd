# File: StateMachine.gd
# Description: Naming-convention state machine (ported from The Village): the host defines state_X_enter/update/exit methods.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-12
# Last edit date: 2026-10-12
# Version: 1.0.0
class_name StateMachine
extends Node
## The host node defines each state as methods:
##   state_NAME_enter()        - on enter (optional)
##   state_NAME_update(delta)  - every physics frame (required: this is how states are discovered)
##   state_NAME_exit()         - on exit (optional)
## Usage in the host's _ready():  $StateMachine.init(self, "idle")

signal state_changed(from: String, to: String)

var current_state: String = ""

var _host: Node
var _states: Dictionary = {}


# Discover states from the host's method names, then enter the initial state.
func init(host: Node, initial_state: String) -> void:
	_host = host
	for method in host.get_method_list():
		var mname: String = method["name"]
		if mname.begins_with("state_") and mname.ends_with("_update"):
			_states[mname.trim_prefix("state_").trim_suffix("_update")] = true
	transition_to(initial_state)


# Leave the current state (calling its exit) and enter `new_state` (calling its enter).
func transition_to(new_state: String) -> void:
	if new_state == current_state:
		return
	if not _states.has(new_state):
		push_error("StateMachine: state '%s' does not exist on %s" % [new_state, _host.name])
		return
	var old_state := current_state
	if old_state != "" and _host.has_method("state_%s_exit" % old_state):
		_host.call("state_%s_exit" % old_state)
	current_state = new_state
	if _host.has_method("state_%s_enter" % new_state):
		_host.call("state_%s_enter" % new_state)
	state_changed.emit(old_state, new_state)


# Physics-frame tick: runs after the host's own _physics_process (parents tick before children).
func _physics_process(delta: float) -> void:
	if current_state.is_empty() or not is_instance_valid(_host):
		return
	_host.call("state_%s_update" % current_state, delta)
