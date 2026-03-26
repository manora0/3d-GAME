extends CharacterBody3D
class_name Player

@export var animationtree : AnimationTree
@export var state_machine : StateMachine

@export var vault_cast_forward: RayCast3D  # points forward at chest height
@export var vault_cast_down: RayCast3D 

@onready var anim: AnimationPlayer = $UAL2/AnimationPlayer
@onready var model = $UAL2
@onready var label = $head/StateLabel3D
@onready var head = $head

@onready var standing_shape = $DefaultCollision
@onready var crouch_shape = $CrouchCollision
@onready var jump_shape = $JumpCollision

@onready var ray_left := $Ray_Left
@onready var ray_right := $Ray_Right

var locomotion : AnimationNodeStateMachinePlayback
var crouch : AnimationNodeStateMachinePlayback
var slide : AnimationNodeStateMachinePlayback
var sprint : AnimationNodeStateMachinePlayback
var falling : AnimationNodeStateMachinePlayback

var midair_blend2 = "parameters/midairs/blend_amount"
var midair_oneshot = "parameters/midair/request"
var crouch_blend = "parameters/locomotion/Crouching/Crouch/blend_position"
var walk_blend = "parameters/locomotion/walk/blend_position"

@export var ray : RayCast3D



enum collision_type {STANDING, CROUCHING, JUMPING}

const SPEED = 15.0
const CROUCH_SPEED = 15.0
const SLIDE_SPEED = 25.0
const RUNSPEED = 25.0
const JUMP_VELOCITY = 20

var gravity_scale : float = 1.0

var current_input : Vector2
var current_velocity : Vector2

func _ready() -> void:
	# init animation playback refs first
	locomotion = animationtree.get("parameters/locomotion/playback")
	crouch = animationtree.get("parameters/locomotion/Crouching/playback")
	slide = animationtree.get("parameters/locomotion/slide/playback")
	sprint = animationtree.get("parameters/locomotion/sprint/playback")
	falling = animationtree.get("parameters/falling_state/playback")
	
	#$FallTimer.timeout.connect(fall_toggle)
	pass

# per-frame, non phyisics
func _process(delta: float) -> void:
	if state_machine.current_state:
		state_machine.current_state.Update(delta)
	
	
	if not is_on_floor() and $FallTimer.paused and not state_machine.current_state.name == "Jump":
		$FallTimer.set_paused(false)
		$FallTimer.start()
	elif is_on_floor() and not $FallTimer.paused:
		$FallTimer.set_paused(true)
		
	if Input.is_action_pressed("aim"):
		animationtree["parameters/cast 2/blend_amount"] = 1.0
	else:
		animationtree["parameters/cast 2/blend_amount"] = 0
		
	if Input.is_key_pressed(KEY_R):
		print("true")
		anim.play("d/Dance")
	

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta * 4  * gravity_scale
	
	current_input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	if state_machine.current_state:
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
	
