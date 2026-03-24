extends State
class_name Standing

enum states {
	IDLE, WALKING, RUNNING
}

const WALKING_SPEED = 15
const RUNNING_SPEED = 30
const FRICTION = 5
const RUN_THRESHOLD = 1.5

var current_state := states.IDLE
var previous_state : states

var path = "parameters/locomotion/Standing/blend_position"
var blend_position: Vector2 = Vector2.ZERO
var target_blend: Vector2 = Vector2.ZERO
var transition_speed: float = 3.0
var was_running: bool = false


func Enter():
	player.locomotion.travel("Standing")

func Exit():
	player.rotation.y = player.head.global_rotation.y
	player.model.rotation = Vector3.ZERO
	pass

func Physics_Update(_delta: float):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var is_running = Input.is_action_pressed("run")
	
	target_blend = input_dir * (2.0 if is_running else 1.0)
	
	var direction := (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	var speed = player.RUNSPEED if is_running else player.SPEED
	player.velocity.x = direction.x * speed
	player.velocity.z = direction.z * speed
	
	if is_running:
		var dir = player.velocity
		dir.y = 0
		player.model.look_at(player.transform.origin - dir, Vector3.UP)

func Update(_delta: float):
	blend_position = blend_position.move_toward(target_blend, transition_speed * _delta)
	player.animationtree[path] = blend_position
	
	var is_running = blend_position.length() >= RUN_THRESHOLD
	
	if is_running and not was_running:
		on_sprint_enter()
	elif not is_running and was_running:
		on_sprint_exit()
		
	was_running = is_running
	check_transition()

func on_sprint_enter():
	player.head.lock_body(false)
	player.spring.travel("d_Sprint")

func on_sprint_exit():
	player.head.lock_body(true)
	player.model.rotation = Vector3.ZERO
	player.spring.travel("d_Sprint_Exit")

func check_transition():
	if Input.is_action_just_pressed("jump"):
		Transitioned.emit(self, "Jump")
		return
	
	if Input.is_action_pressed("run") and Input.is_action_pressed("slide"):
		Transitioned.emit(self, "Slide")
		return

	if Input.is_action_pressed("slide"):
		Transitioned.emit(self, "Crouch")
		return
