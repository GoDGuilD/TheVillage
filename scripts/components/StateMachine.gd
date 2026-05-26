extends Node
class_name StateMachine
## Máquina de estados genérica basada en convención de nombres.
##
## El nodo padre define estados como métodos:
##   state_NOMBRE_enter()        — al entrar (opcional)
##   state_NOMBRE_update(delta)  — cada physics frame
##   state_NOMBRE_exit()         — al salir (opcional)
##
## Inicialización en el _ready() del padre:
##   @onready var _fsm: StateMachine = $StateMachine
##   func _ready(): _fsm.init(self, "idle")

signal state_changed(from: String, to: String)

var current_state: String = ""

var _owner_node: Node
var _states: Dictionary = {}

func init(owner: Node, initial_state: String) -> void:
	_owner_node = owner
	# Descubrimiento automático de estados por nombre de método
	for method in owner.get_method_list():
		var mname: String = method["name"]
		if mname.begins_with("state_") and mname.ends_with("_update"):
			var sname := mname.trim_prefix("state_").trim_suffix("_update")
			_states[sname] = true
	transition_to(initial_state)

func transition_to(new_state: String) -> void:
	if new_state == current_state:
		return
	if not _states.has(new_state):
		push_error("StateMachine: estado '%s' no existe en %s" % [new_state, _owner_node.name])
		return

	var old_state := current_state

	if old_state != "" and _owner_node.has_method("state_%s_exit" % old_state):
		_owner_node.call("state_%s_exit" % old_state)

	current_state = new_state

	if _owner_node.has_method("state_%s_enter" % new_state):
		_owner_node.call("state_%s_enter" % new_state)

	state_changed.emit(old_state, new_state)

func _physics_process(delta: float) -> void:
	## Usa physics_process (no process) porque el dueño usa move_and_slide().
	if current_state.is_empty() or not is_instance_valid(_owner_node):
		return
	_owner_node.call("state_%s_update" % current_state, delta)
