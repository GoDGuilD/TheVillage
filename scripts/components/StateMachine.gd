extends Node
class_name StateMachine
## Generic state machine based on naming convention.
##
## The parent node defines states as methods:
##   state_NAME_enter()        — on enter (optional)
##   state_NAME_update(delta)  — every physics frame
##   state_NAME_exit()         — on exit (optional)
##
## Initialization in the parent's _ready():
##   @onready var _fsm: StateMachine = $StateMachine
##   func _ready(): _fsm.init(self, "idle")

signal state_changed(from: String, to: String)

var current_state: String = ""

var _owner_node: Node
var _states: Dictionary = {}

func init(host: Node, initial_state: String) -> void:
	_owner_node = host
	# Automatic state discovery by method name
	for method in host.get_method_list():
		var mname: String = method["name"]
		if mname.begins_with("state_") and mname.ends_with("_update"):
			var sname := mname.trim_prefix("state_").trim_suffix("_update")
			_states[sname] = true
	transition_to(initial_state)

func transition_to(new_state: String) -> void:
	if new_state == current_state:
		return
	if not _states.has(new_state):
		push_error("StateMachine: state '%s' does not exist on %s" % [new_state, _owner_node.name])
		return

	var old_state := current_state

	if old_state != "" and _owner_node.has_method("state_%s_exit" % old_state):
		_owner_node.call("state_%s_exit" % old_state)

	current_state = new_state

	if _owner_node.has_method("state_%s_enter" % new_state):
		_owner_node.call("state_%s_enter" % new_state)

	state_changed.emit(old_state, new_state)

func _physics_process(delta: float) -> void:
	## Uses physics_process (not process) because the owner uses move_and_slide().
	if current_state.is_empty() or not is_instance_valid(_owner_node):
		return
	_owner_node.call("state_%s_update" % current_state, delta)
