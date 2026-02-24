extends State
class_name Idle

var move_direction : Vector3

func Enter():
	if player.anim:
		player.anim.play("d/Idle")
	
func Exit():
	pass
	
func Update(_delta: float):
	if Input.is_action_just_pressed("Dance"):
		Transitioned.emit(self, "Dance")
	
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
	
