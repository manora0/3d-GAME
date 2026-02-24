extends CharacterBody3D
class_name Player

@onready var anim: AnimationPlayer = $UAL2/AnimationPlayer
@export var state_machine : StateMachine
@onready var model = $UAL2
@onready var label = $head/StateLabel3D

const SPEED = 5.0
const RUNSPEED = 30.0
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
	
	state_machine.current_state.Physics_Update(delta)
	move_and_slide()
