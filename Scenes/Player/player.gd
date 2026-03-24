extends CharacterBody3D
class_name Player

@export var animationtree : AnimationTree
@export var state_machine : StateMachine

@onready var anim: AnimationPlayer = $UAL2/AnimationPlayer
@onready var model = $UAL2
@onready var label = $head/StateLabel3D
@onready var head = $head

@onready var standing_shape = $DefaultCollision
@onready var crouch_shape = $CrouchCollision
@onready var jump_shape = $JumpCollision

@onready var locomotion : AnimationNodeStateMachinePlayback = animationtree.get("parameters/locomotion/playback")
@onready var crouch : AnimationNodeStateMachinePlayback = animationtree.get("parameters/locomotion/crouch/playback")
@onready var slide : AnimationNodeStateMachinePlayback = animationtree.get("parameters/locomotion/slide/playback")
@onready var sprint : AnimationNodeStateMachinePlayback = animationtree.get("parameters/locomotion/sprint/playback")
@onready var falling : AnimationNodeStateMachinePlayback = animationtree.get("parameters/falling_state/playback")
var midair_blend2 = "parameters/midairs/blend_amount"
var midair_oneshot = "parameters/midair/request"
var crouch_blend = "parameters/locomotion/crouch/crouching/blend_position"
var walk_blend = "parameters/locomotion/walk/blend_position"

@export var ray : RayCast3D



enum collision_type {STANDING, CROUCHING, JUMPING}

const SPEED = 20.0
const CROUCH_SPEED = 10.0
const RUNSPEED = 30.0
const JUMP_VELOCITY = 13

var current_input : Vector2
var current_velocity : Vector2

func _ready() -> void:
	$FallTimer.timeout.connect(fall_toggle)
	pass

# per-frame, non phyisics
func _process(delta: float) -> void:
	state_machine.current_state.Update(delta)
	
	
	if not is_on_floor() and $FallTimer.paused and not state_machine.current_state.name == "Jump":
		$FallTimer.set_paused(false)
		$FallTimer.start()
	elif is_on_floor() and not $FallTimer.paused:
		$FallTimer.set_paused(true)
	

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta * 2
	
	current_input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	state_machine.current_state.Physics_Update(delta)
	move_and_slide()
	
	
func request_collision_shape(type: int):
	if standing_shape:
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
				
func fall_toggle():
	state_machine.force_change_state("Jump")
	
