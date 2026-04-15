extends State

@export var initial_state : State

var prev_state : State
var current_state : State
var states : Dictionary = {}

func _ready():
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.Transitioned.connect(on_child_transition)

			child.player = owner

	if initial_state:
		initial_state.Enter()
		current_state = initial_state

func _process(delta):
	if current_state:
		current_state.Update(delta)

func _physics_process(delta: float) -> void:
		if current_state:
			current_state.Physics_Update(delta)

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
	print('new state transitioned from ' + state.name + ' to ' + new_state_name)
	current_state = new_state

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
