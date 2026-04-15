extends StateMachine
class_name Grounded

enum movement_mode { IDLE, WALK, SPRINT }

const MAXIMUM_SPEED := 50.0
const FRICTION := 15.0
const GRAVITY := 9.8
const SPEED := {
	movement_mode.IDLE: 0.0,
	movement_mode.WALK: 15.0,
	movement_mode.SPRINT: 30.0
}
const ACCEL := {
	movement_mode.IDLE: 0.0,
	movement_mode.WALK: 40.0,
	movement_mode.SPRINT: 60.0
}

var mode := movement_mode.IDLE
var input_dir := Vector2.ZERO

func Enter():
	force_change_state("idle")

func Physics_Update(_delta: float):
	if not player.is_on_floor():
		#transition to airborne
		pass
	
	input_dir = Input.get_vector("move_right", "move_left", "move_back", "move_forward")
	var direction := (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if current_state is Crouch or current_state is Slide:
		pass







func _process(delta: float) -> void:
	if !player.is_on_floor():
		#transition to airborne
		pass

func _physics_process(delta: float) -> void:
	
	if input_dir == Vector2.ZERO:
		Transitioned.emit(self, "Idle")
	
	
	if direction == Vector3.ZERO:
		player.velocity.x = move_toward(player.velocity.x, 0, GROUNDED_FRICTION)
		player.velocity.z = move_toward(player.velocity.z, 0, GROUNDED_FRICTION)
	
	else: 
		player.velocity.x = direction.x * cur_speed
		player.velocity.z = direction.z * cur_speed


	
