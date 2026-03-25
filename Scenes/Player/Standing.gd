extends State
class_name Standing

const RUN_THRESHOLD = 1.5
var path = "parameters/locomotion/Standing/blend_position"
var blend_position: Vector2 = Vector2.ZERO
var target_blend: Vector2 = Vector2.ZERO
var transition_speed: float = 3.0
var was_running: bool = false

func Enter():
	player.locomotion.travel("Standing")

func Exit():
	if was_running:
		player.head.lock_body(true)

func Physics_Update(_delta: float):
	var input_dir = Input.get_vector("move_right", "move_left", "move_back", "move_forward")
	var is_running = Input.is_action_pressed("run")

	target_blend = input_dir * (2.0 if is_running else 1.0)

	var direction := (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	var speed = player.RUNSPEED if is_running else player.SPEED
	player.velocity.x = direction.x * speed
	player.velocity.z = direction.z * speed

	if is_running and direction != Vector3.ZERO:
		var dir = player.velocity
		dir.y = 0
		player.model.look_at(player.transform.origin - dir, Vector3.UP)

func Update(_delta: float):
	blend_position = blend_position.move_toward(target_blend, transition_speed * _delta)
	player.animationtree[path] = blend_position

	var is_running = blend_position.length() >= RUN_THRESHOLD

	if is_running and not was_running:
		player.head.lock_body(true)
		pass
	elif not is_running and was_running:
		player.head.lock_body(true)
		player.model.rotation = Vector3.ZERO

	was_running = is_running
	check_transition()

func check_transition():
	if Input.is_action_just_pressed("jump"):
		Transitioned.emit(self, "Jump")
		return
	if Input.is_action_pressed("slide"):
		Transitioned.emit(self, "Crouching")
		return
