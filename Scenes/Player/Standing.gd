extends State
class_name Standing

const RUN_THRESHOLD = 1.5
var path = "parameters/locomotion/Standing/blend_position"
var blend_position: Vector2 = Vector2.ZERO
var target_blend: Vector2 = Vector2.ZERO
var transition_speed: float = 3.0
var was_running: bool = false
var was_moving: bool = false

func Enter():
	#player.animationtree.set("parameters/StateMachine/Moving/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	player.move_speed = player.SPEED
	player.locomotion.travel("Standing")

func Exit():
	pass
	#if was_running:
		#player.head.lock_body(true)

func Physics_Update(_delta: float):
	player.direction = Vector3(-player.inputdir.x, 0, -player.inputdir.z).rotated(Vector3.UP, player.camera_T).normalized()

	var is_running_input = Input.is_action_pressed("run")
	target_blend = Vector2(player.inputdir.x, player.inputdir.z) * (2.0 if is_running_input else 1.0)

	if player.direction != Vector3.ZERO:
		if player.anim_isgrounded:
			player.player_velocity = player.player_velocity.lerp(player.direction * player.move_speed, 8 * _delta)
			player.canmove = true

		player.rotation.y = lerp_angle(
			player.rotation.y,
			atan2(player.direction.x, player.direction.z),
			player.TURN_SPEED * _delta
		)

		if not was_moving:
			pass
			#player.animationtree.set("parameters/StateMachine/Moving/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

		was_moving = true
	else:
		if player.anim_isgrounded:
			player.player_velocity = player.player_velocity.lerp(Vector3.ZERO, 15 * _delta)
			player.canmove = false

			if was_moving:
				pass
				#player.animationtree.set("parameters/StateMachine/Moving/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		else:
			player.player_velocity = player.player_velocity.lerp(Vector3.ZERO, _delta)

		was_moving = false

	player.velocity = player.player_velocity

func Update(_delta: float):
	blend_position = blend_position.move_toward(target_blend, transition_speed * _delta)
	player.animationtree[path] = blend_position

	var is_running = blend_position.length() >= RUN_THRESHOLD

	if is_running and not was_running:
		player.move_speed = player.RUNSPEED
		player.animationtree.set("parameters/StateMachine/Moving/Transition/transition_request", "Sprint")
		#player.head.lock_body(false)
	elif not is_running and was_running:
		player.move_speed = player.SPEED
		#player.head.lock_body(true)
		player.animationtree.set("parameters/StateMachine/Moving/Transition/transition_request", "Jog")

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
