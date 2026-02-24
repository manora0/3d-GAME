extends CharacterBody3D
class_name Player

@onready var anim: AnimationPlayer = $UAL2/AnimationPlayer
@export var state_machine : StateMachine
@onready var model = $UAL2
@onready var label = $head/StateLabel3D
@export var animationtree : AnimationTree

const SPEED = 20.0
const RUNSPEED = 30.0
const JUMP_VELOCITY = 13

var current_input : Vector2
var current_velocity : Vector2

func _ready() -> void:
	pass
	

# per-frame, non phyisics
func _process(delta: float) -> void:
	state_machine.current_state.Update(delta)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta * 2
	
	state_machine.current_state.Physics_Update(delta)
	move_and_slide()
