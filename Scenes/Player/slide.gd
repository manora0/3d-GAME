extends State

var path = "parameters/Transition/current_state"
var path2 = "parameters/Transition/transition_request"

func Enter():
	player.animationtree[path2] = "state_1"

func Exit():
	pass
	
func Physics_Update(_delta: float):
	pass
	
func Update(_delta:float):
	if not Input.is_action_pressed("slide"):
		player.animationtree[path2] = "state_0"
		Transitioned.emit(self, "Run")
