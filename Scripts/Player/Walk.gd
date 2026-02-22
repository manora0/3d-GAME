extends State

func Enter():
	player.anim.play("Walk")
	
func Exit():
	pass
	
func Update(_delta: float):
	pass
	
func Physics_Update(_delta: float):
	var input_dir := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	
	if input_dir == Vector2.ZERO:
		Transitioned.emit(self, "Idle")
		
	var direction := (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	player.velocity.x = direction.x * player.SPEED
	player.velocity.z = direction.z * player.SPEED
	
	var dir = player.velocity
	dir.y = 0
	player.model.look_at(player.transform.origin - dir, Vector3.UP)
	
	if Input.is_action_pressed('jump'):
		Transitioned.emit(self, "Jump")
		
	if Input.is_action_just_pressed("run"):
		Transitioned.emit(self, "Run")
