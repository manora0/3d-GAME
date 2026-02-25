extends State

var path = "parameters/Transition/current_state"
var path2 = "parameters/Transition/transition_request"

func Enter():
	player.head.lock_body(false)
	player.locomotion.travel("slide")

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
	if Input.is_action_pressed("jump"):
		Transitioned.emit(self, "Jump")
