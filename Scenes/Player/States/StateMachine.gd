extends State
class_name StateMachine

@export var initial_state : State

var prev_state : State
var current_state : State
var states : Dictionary = {}

"""
On ready this script will get all immediate children of its node and store them
in the states dictionary. For each state it will connect the on_child_transition
function to this scripts transition function and set the childs player to the 
owner of this script.
"""
func _ready():
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.Transitioned.connect(on_child_transition)
			
			child.player = owner
	
	if initial_state:
		initial_state.Enter()
		current_state = initial_state

"""
Calls the process function of the current active state
"""
func _process(delta: float) -> void:
	if current_state:
		current_state.Update(delta)

func _physics_process(delta: float) -> void:
		if current_state:
			current_state.Physics_Update(delta)

"""
checks if given state and new_state_name are valid states, then exits current state
and sets new state as current state and enters new state.
"""
func on_child_transition(state, new_state_name):
	if state != current_state: 
		return
	
	var new_state = states.get(new_state_name.to_lower())
	
	if !new_state:
		return
	
	if current_state:
		current_state.Exit()
	
	prev_state = current_state
	new_state.Enter()
	current_state = new_state
	
	print('new state transitioned from ' + state.name + ' to ' + new_state_name)
	var label3d = get_parent().get_node("head/StateLabel3D") as Label3D
	if label3d:
		label3d.text = new_state_name


func force_change_state(new_state_name):
	var new_state = states.get(new_state_name.to_lower())
	if !new_state:
		return
		
	if current_state:
		current_state.Exit()
	
	prev_state = current_state
	new_state.Enter()
	current_state = new_state

	print('new state transitioned to ' + new_state_name)
	
	var label3d = get_parent().get_node("head/StateLabel3D") as Label3D
	if label3d:
		label3d.text = new_state_name
