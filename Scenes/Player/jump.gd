extends State
class_name Jump

var can_jump: bool = true
var can_transition: bool = false
var timer: Timer
var entry_velocity: Vector2

func Enter():
	can_transition = false
	can_jump = true
	
	# capture horizontal velocity at jump entry
	entry_velocity = Vector2(player.velocity.x, player.velocity.z)
	
	# reuse timer
	if not timer:
		timer = Timer.new()
		add_child(timer)
		timer.one_shot = true
		timer.timeout.connect(allow_transition)
	timer.start(0.1)
	
	player.animationtree[player.midair_oneshot] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	player.falling.travel("d_Jump_Start")

func Exit():
	player.falling.travel("d_Jump_Land")
	pass

func Physics_Update(_delta: float):
	if Input.is_action_pressed("jump") and can_jump:
		player.velocity.y = player.JUMP_VELOCITY
		can_jump = false

	var cur_input = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	var direction := (player.transform.basis * Vector3(cur_input.x, 0, cur_input.y)).normalized()

	if cur_input != Vector2.ZERO:
		# blend between entry velocity and input directed speed for air control
		var target = Vector2(direction.x, direction.z) * player.SPEED
		entry_velocity = entry_velocity.lerp(target, 0.05)
	
	print(player.velocity)
	
	player.velocity.x = entry_velocity.x
	player.velocity.z = entry_velocity.y
	
	print(player.is_on_floor())
	
	if player.is_on_floor() and can_transition:
		Transitioned.emit(self, "Standing")

func allow_transition():
	can_transition = true
