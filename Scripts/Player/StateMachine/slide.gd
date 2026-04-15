extends State
class_name Slide

func Enter():
	player.head.lock_body(false)
	player.locomotion.travel("slide")
	player.slide.travel("Slide_Start")

func Exit():
	player.head.lock_body(true)
	player.slide.travel("Slide_Exit")
	
func Physics_Update(_delta: float):
	pass
	
func Update(_delta:float):
	
	if not Input.is_action_pressed("slide"):
		if Input.is_action_pressed("run"):
			player.sprint.travel("d_Sprint")
			Transitioned.emit(self, "Run")
		else:
			Transitioned.emit(self,"Walk")
	elif Input.is_action_pressed("jump"):
		Transitioned.emit(self, "Jump")
