extends State
class_name Crouch


var transitionSpeed = 3
var cur_velocity : Vector2 
var cur_input : Vector2

func Enter():
	player.locomotion.travel("crouch")
	
func Exit():
	player.crouch.travel("d_Crouch_Exit")
	
func Update(_delta: float):
	player.current_velocity = player.current_velocity.move_toward(cur_input, transitionSpeed * _delta)
	if player.animationtree:
		player.animationtree[player.crouch_blend] = player.current_velocity
	
	if not Input.is_action_pressed("slide"):
		Transitioned.emit(self, "Walk")
	if Input.is_action_pressed("jump"):
		Transitioned.emit(self, "jump")
	
func Physics_Update(_delta: float):
	cur_input = Input.get_vector("move_right", "move_left", "move_back", "move_forward")
		
	var direction := (player.transform.basis * Vector3(cur_input.x, 0, cur_input.y)).normalized()
	
	player.velocity.x = direction.x * player.CROUCH_SPEED
	player.velocity.z = direction.z * player.CROUCH_SPEED
	
