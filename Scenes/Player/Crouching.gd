extends State
class_name Crouching

var blend_position: Vector2 = Vector2.ZERO
var target_blend: Vector2 = Vector2.ZERO
var transition_speed: float = 3.0
var was_sliding: bool = false

const SLIDE_THRESHOLD = 1.5

func Enter():
	player.locomotion.travel("Crouching")
	player.crouch.travel("d_Crouch_Enter")

func Exit():
	player.crouch.travel("d_Crouch_Exit")
	if was_sliding:
		player.head.lock_body(true)
		player.model.rotation = Vector3.ZERO

func Physics_Update(_delta: float):
	var input_dir = Input.get_vector("move_left", "move_right", "move_back", "move_forward")

	target_blend = input_dir * (2.0 if Input.is_action_pressed("run") else 1.0)

	var direction := (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed = player.SLIDESPEED if was_sliding else player.CROUCHSPEED
	player.velocity.x = direction.x * speed
	player.velocity.z = direction.z * speed

	if was_sliding and direction != Vector3.ZERO:
		var dir = player.velocity
		dir.y = 0
		player.model.look_at(player.transform.origin - dir, Vector3.UP)

func Update(_delta: float):
	blend_position = blend_position.move_toward(target_blend, transition_speed * _delta)
	player.animationtree[player.crouch_blend] = blend_position

	var is_sliding = blend_position.length() >= SLIDE_THRESHOLD

	if is_sliding and not was_sliding:
		on_slide_enter()
	elif not is_sliding and was_sliding:
		on_slide_exit()

	was_sliding = is_sliding
	check_transitions()

func on_slide_enter():
	player.head.lock_body(false)
	player.slide.travel("d_Slide_Start")

func on_slide_exit():
	player.head.lock_body(true)
	player.model.rotation = Vector3.ZERO
	player.slide.travel("d_Slide_Exit")

func check_transitions():
	if Input.is_action_just_pressed("jump"):
		Transitioned.emit(self, "Jump")
		return

	if not Input.is_action_pressed("slide"):
		if Input.is_action_pressed("run"):
			Transitioned.emit(self, "Standing")
		else:
			Transitioned.emit(self, "Standing")
		return
