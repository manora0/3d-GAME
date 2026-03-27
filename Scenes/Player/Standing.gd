extends State
class_name Standing

const RUN_THRESHOLD = 1.5
var path = "parameters/locomotion/Standing/blend_position"
var blend_position: Vector2 = Vector2.ZERO
var target_blend: Vector2 = Vector2.ZERO
var transition_speed: float = 3.0
var was_running: bool = false

var other_path = "parameters/StateMachine/Moving/OneShot/request"

func Enter():
	player.move_speed = player.SPEED
	player.locomotion.travel("Standing")

func Exit():
	if was_running:
		player.head.lock_body(true)

func Physics_Update(_delta: float):
	player.direction = Vector3(-player.inputdir.x,0, -player.inputdir.z).rotated(Vector3.UP, player.camera_T).normalized()

	if player.direction != Vector3.ZERO:
		if player.anim_isgrounded:
			player.player_velocity = player.player_velocity.lerp(player.direction * player.move_speed, 8 * _delta)
			player.canmove = true
	else:
		if player.anim_isgrounded: ## IF NOT MOVING
			player.player_velocity = player.player_velocity.lerp(Vector3.ZERO, 15 * _delta) ## MOVE TOWARDS VELOCITY OF ZERO
			player.canmove = false 
		else:
			player.player_velocity = player.player_velocity.lerp(player.direction * player.move_speed, _delta) ## MOVE TOWARDS ZERO 
	
	
	
	player.velocity = player.player_velocity
	
	if player.direction != Vector3.ZERO:
		player.rotation.y = lerp_angle(
			player.rotation.y,
			atan2(player.direction.x, player.direction.z),
			player.TURN_SPEED * _delta
		)
	
	
	var is_running = Input.is_action_pressed("run")
	
	if is_running:
		player.animationtree.set("parameters/StateMachine/Moving/Transition/transition_request", "Sprint")
#
	target_blend = Vector2(player.inputdir.x, player.inputdir.z) * (2.0 if is_running else 1.0)
#
	#var direction := (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	#
	#var speed = player.RUNSPEED if is_running else player.SPEED
	#player.velocity.x = direction.x * speed
	#player.velocity.z = direction.z * speed
#
	#if is_running and direction != Vector3.ZERO:
		#var dir = player.velocity
		#dir.y = 0
		#player.mesh.look_at(player.transform.origin - dir, Vector3.UP)

func Update(_delta: float):
	blend_position = blend_position.move_toward(target_blend, transition_speed * _delta)
	player.animationtree[path] = blend_position

	var is_running = blend_position.length() >= RUN_THRESHOLD

	if is_running and not was_running:
		player.head.lock_body(true)
		pass
	elif not is_running and was_running:
		player.head.lock_body(true)
		player.mesh.rotation = Vector3.ZERO

	was_running = is_running
	check_transition()

func check_transition():
	if Input.is_action_just_pressed("jump"):
		Transitioned.emit(self, "Jump")
		return
	if Input.is_action_pressed("slide"):
		Transitioned.emit(self, "Crouching")
		return
