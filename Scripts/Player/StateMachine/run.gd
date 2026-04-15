extends State

var playback_path = "parameters/Locomotion/playback"
var playback

var sprint_state_machine = "parameters/Locomotion/Running/playback"
var sprint_state 


func Enter():
	player.locomotion.travel("sprint")

func Exit():
	player.sprint.travel("d_Sprint_Exit")
	
	player.rotation.y = player.head.global_rotation.y
	player.model.rotation = Vector3.ZERO
	
func Update(_delta: float):
	pass
	
func Physics_Update(_delta: float):
	var input_dir := Input.get_vector("move_right", "move_left", "move_back", "move_forward")
	
	if input_dir == Vector2.ZERO:
		Transitioned.emit(self, "Idle")
		
	var direction := (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	player.velocity.x = direction.x * player.RUNSPEED
	player.velocity.z = direction.z * player.RUNSPEED
	
	var dir = player.velocity
	dir.y = 0
	player.model.look_at(player.transform.origin - dir, Vector3.UP)
	
	if Input.is_action_pressed('jump'):
		Transitioned.emit(self, "Jump")
		
	if not Input.is_action_pressed("run"):
		Transitioned.emit(self, "Walk")
		
	if Input.is_action_pressed("slide"):
		Transitioned.emit(self, "Slide")

func enter_run():
	playback.travel("Running")
