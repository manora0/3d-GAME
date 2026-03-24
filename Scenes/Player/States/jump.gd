extends State

var can_jump : bool = true
var can_transition : bool
var playback_path = "parameters/Locomotion/playback"

var cur_velocity : Vector2 
var cur_input : Vector2

func Enter():
	can_transition = false

	var timer := Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.timeout.connect(allow_transition)
	timer.start(.1)
	
	player.animationtree[player.midair_oneshot] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	can_jump = true
	player.falling.travel("d_Jump_Start")
	
	#player.request_collision_shape(player.collision_type.JUMPING)
	
func Exit():
	player.falling.travel("d_Jump_Land")
	
func Update(_delta: float):
	pass
	
func Physics_Update(_delta: float):
	if Input.is_action_pressed("ui_accept") and can_jump:
		player.velocity.y = player.JUMP_VELOCITY
		can_jump = false
	
	cur_input = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
		
	var direction := (player.transform.basis * Vector3(cur_input.x, 0, cur_input.y)).normalized()
	
	player.velocity.x = direction.x * player.SPEED
	player.velocity.z = direction.z * player.SPEED

	if player.is_on_floor() and can_transition:
		if Input.is_action_pressed("run"):
			player.sprint.travel("d_Sprint")
			Transitioned.emit(self, "Run")
		else:
			Transitioned.emit(self, 'Idle')
			
func allow_transition():
	can_transition = true
