extends CharacterBody3D
class_name Player

@export var animationtree : AnimationTree
@export var state_machine : StateMachine

@onready var anim: AnimationPlayer = $UAL2/AnimationPlayer
@onready var model = $UAL2
@onready var label = $head/StateLabel3D

@onready var standing_shape = $DefaultCollision
@onready var crouch_shape = $CrouchCollision
@onready var jump_shape = $JumpCollision

enum collision_type {STANDING, CROUCHING, JUMPING}

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
	
func request_collision_shape(type: int):
	standing_shape.disabled = true
	crouch_shape.disabled = true
	jump_shape.disabled = true
	
	match type:
		collision_type.STANDING:
			standing_shape.disabled = false
		collision_type.CROUCHING:
			crouch_shape.disabled = false
		collision_type.JUMPING:
			jump_shape.disabled = false
