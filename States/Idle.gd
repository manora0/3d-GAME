extends State
class_name Idle

var move_direction : Vector3

func Enter():
	player.anim.play("Idle")
	
func Exit():
	pass
	
func Update(_delta: float):
	pass
	
func Physics_Update(_delta: float):
	var input_dir := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	
	if input_dir != Vector2.ZERO:
		print('HERE')
		Transitioned.emit(self, "walk")
		
	if Input.is_action_just_pressed("jump"):
		Transitioned.emit(self, "jump")
	
