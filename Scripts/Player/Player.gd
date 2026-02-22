extends CharacterBody3D
class_name Player

@export var anim: AnimationPlayer 
@export var state_machine : StateMachine

const SPEED = 5.0
const JUMP_VELOCITY = 8.5

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	state_machine.force_change_state(state_machine.initial_state.name)

func _input(event: InputEvent) -> void:
	if(event is InputEventMouseMotion):
		rotate_camera(event.relative)
	if(event is InputEventKey and event.is_pressed() and not event.is_echo()):
		if(event.shift_pressed && event.keycode == KEY_R):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if(event is InputEventMouseButton):
		if(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			

func rotate_camera(vector: Vector2) -> void:
	self.rotate_y(vector.x * .001)
	var clamped = clamp($head.rotation.x + vector.y * .001, -1.5, 1.5)
	$head.rotation.x = clamped

# per-frame, non phyisics
func _process(_delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta * 2
	
	move_and_slide()
	state_machine.current_state.Physics_Update(delta)
	
		

	## Handle jump.
	#if Input.is_action_just_pressed("ui_accept"):
		#velocity.y = JUMP_VELOCITY
		#$model/UAL1_Standard/AnimationPlayer.play("Jump")
#
	## Get the input direction and handle the movement/deceleration.
	## As good practice, you should replace UI actions with custom gameplay actions.
	#var input_dir := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	#var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#if direction:
		#velocity.x = direction.x * SPEED
		#velocity.z = direction.z * SPEED
		#var dir = velocity
		#dir.y = 0
		#$model.look_at(transform.origin - dir, Vector3.UP)
		#$model/UAL1_Standard/AnimationPlayer.play("Walk")
	#else:
		#$model/UAL1_Standard/AnimationPlayer.play("Idle")
		#velocity.x = move_toward(velocity.x, 0, SPEED)
		#velocity.z = move_toward(velocity.z, 0, SPEED)
#
	#move_and_slide()
