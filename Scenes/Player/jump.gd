extends State
class_name Jump

var can_jump: bool = true
var can_transition: bool = false
var timer: Timer
var entry_velocity: Vector2

func Enter():
	can_transition = false
	can_jump = true
	entry_velocity = Vector2(player.velocity.x, player.velocity.z)
	
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

func Physics_Update(_delta: float):
	if Input.is_action_pressed("jump") and can_jump:
		player.velocity.y = player.JUMP_VELOCITY
		can_jump = false

	var cur_input = Input.get_vector("move_right", "move_left", "move_back", "move_forward")
	var direction := (player.transform.basis * Vector3(cur_input.x, 0, cur_input.y)).normalized()

	if cur_input != Vector2.ZERO:
		# slight air control, very low lerp to barely deviate from entry velocity
		var target = Vector2(direction.x, direction.z) * entry_velocity.length()
		entry_velocity = entry_velocity.lerp(target, 0.02 * _delta * 60)

	# correctly map Vector2 x/y to velocity x/z
	player.velocity.x = entry_velocity.x
	player.velocity.z = entry_velocity.y  # Vector2.y maps to world Z

	if player.is_on_floor() and can_transition:
		Transitioned.emit(self, "Standing")
	
	check_transition()
	check_vault()

func allow_transition():
	can_transition = true

func check_transition():
	if player.ray_left.is_colliding() or player.ray_right.is_colliding():
		player.falling.start("d_Jump")
		Transitioned.emit(self, "Wallrun")
		
func check_vault():
	if player.vault_cast_forward.is_colliding():
		var normal = player.vault_cast_forward.get_collision_normal()
		# make sure its a wall not a floor
		if abs(normal.dot(Vector3.UP)) < 0.3:
			Transitioned.emit(self, "Vault")
			player.falling.travel("end")
