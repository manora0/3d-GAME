extends State

var transitionSpeed = 3

var cur_velocity : Vector2 
var cur_input : Vector2

func Enter():
	pass
	
func Exit():
	pass
	
func Update(_delta: float):
	player.current_velocity = player.current_velocity.move_toward(cur_input, transitionSpeed * _delta)
	if player.animationtree:
		player.animationtree["parameters/Locomotion/walking/blend_position"] = player.current_velocity

func Physics_Update(_delta: float):
	cur_input = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	
	if cur_input == Vector2.ZERO:
		Transitioned.emit(self, "Idle")
		
	var direction := (player.transform.basis * Vector3(cur_input.x, 0, cur_input.y)).normalized()
	
	player.velocity.x = direction.x * player.SPEED
	player.velocity.z = direction.z * player.SPEED
	
	
	if Input.is_action_pressed('jump'):
		Transitioned.emit(self, "Jump")
		
	if Input.is_action_just_pressed("run"):
		Transitioned.emit(self, "Run")
