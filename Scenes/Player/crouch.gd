extends State

var transition_current_state = "parameters/Transition/current_state"
var transition_state_request = "parameters/Transition/transition_request"

var crouch_state_machine_path = "parameters/Crouch/Crouching/blend_position"
var c_state_machine

var crouch_blend_position = "parameters/Crouch/Crouching/blend_position"



var transitionSpeed = 3
var cur_velocity : Vector2 
var cur_input : Vector2

func Enter():
		player.animationtree[transition_state_request] = "state_2"
	
func Exit():
	pass
	
func Update(_delta: float):
	player.current_velocity = player.current_velocity.move_toward(cur_input, transitionSpeed * _delta)
	if player.animationtree:
		player.animationtree[crouch_blend_position] = player.current_velocity
	
	if not Input.is_action_pressed("slide"):
		player.animationtree[transition_state_request] = "state_0"
		Transitioned.emit(self, "Walk")
	
func Physics_Update(_delta: float):
	cur_input = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	
	if cur_input == Vector2.ZERO:
		Transitioned.emit(self, "Idle")
		
	var direction := (player.transform.basis * Vector3(cur_input.x, 0, cur_input.y)).normalized()
	
	player.velocity.x = direction.x * player.SPEED
	player.velocity.z = direction.z * player.SPEED
	

func check_state_change():
	if Input.is_action_pressed('jump'):
		Transitioned.emit(self, "Jump")
		
	if Input.is_action_just_pressed("run"):
		Transitioned.emit(self, "Run")
