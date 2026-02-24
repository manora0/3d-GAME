extends State
class_name Idle

var move_direction : Vector3

func Enter():
	pass
	
func Exit():
	pass
	
func Update(_delta: float):
	if Input.is_action_just_pressed("Dance"):
		Transitioned.emit(self, "Dance")
	
	player.current_velocity = player.current_velocity.move_toward(Vector2.ZERO, 1 * _delta)
	if player.animationtree:
		player.animationtree["parameters/Locomotion/walking/blend_position"] = player.current_velocity
	
func Physics_Update(_delta: float):
	var input_dir := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	
	player.velocity.x = move_toward(player.velocity.x, 0, player.SPEED)
	player.velocity.z = move_toward(player.velocity.z, 0, player.SPEED)
	
	if input_dir != Vector2.ZERO:
		if Input.is_action_pressed("run"):
			Transitioned.emit(self, "run")
		else:
			Transitioned.emit(self, "walk")

	if Input.is_action_just_pressed("jump"):
		Transitioned.emit(self, "jump")
	
