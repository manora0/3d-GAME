extends State


func Enter():
	player.anim.play("d/Dance")
	
func Exit():
	pass
	
func Physics_Update(_delta: float):
	pass
		
	
func Update(_delta:float):
	if Input.is_action_just_pressed("Dance"):
		Transitioned.emit(self, "Idle")
