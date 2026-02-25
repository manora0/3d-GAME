extends State


func Enter():
	player.locomotion.travel("d_Dance")

	
func Exit():
	player.locomotion.travel("walk")
	
func Physics_Update(_delta: float):
	pass
		
	
func Update(_delta:float):
	if not Input.is_action_pressed("Dance"):
		Transitioned.emit(self, "Idle")
