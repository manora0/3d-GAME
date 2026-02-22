extends State


func Enter():
	player.anim.play("Jump")
	
func Exit():
	pass
	
func Update(_delta: float):
	pass
	
func Physics_Update(_delta: float):
	if Input.is_action_just_pressed("ui_accept"):
		player.velocity.y = player.JUMP_VELOCITY
		player.anim.play("Jump")
	
	if player.is_on_floor():
		Transitioned.emit(self, "Idle")
