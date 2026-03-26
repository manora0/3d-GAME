extends CharacterBody3D
class_name Player

# player
@onready var player := $UAL2
@onready var mesh := $UAL2/Armature

# animation tree
@onready var anim  := $UAL2/AnimationPlayer
@onready var animationtree := $UAL2/AnimationTree2

var locomotion : AnimationNodeStateMachinePlayback
var crouch : AnimationNodeStateMachinePlayback
var slide : AnimationNodeStateMachinePlayback
var sprint : AnimationNodeStateMachinePlayback
var falling : AnimationNodeStateMachinePlayback

var midair_blend2 = "parameters/midairs/blend_amount"
var midair_oneshot = "parameters/midair/request"
var crouch_blend = "parameters/locomotion/Crouching/Crouch/blend_position"
var walk_blend = "parameters/locomotion/walk/blend_position"

# camera
@onready var head = $head

# state
@export var state_machine : StateMachine

# ray casts
@export var vault_cast_forward: RayCast3D  # points forward at chest height
@export var vault_cast_down: RayCast3D 
@export var ray : RayCast3D
@onready var ray_left := $Ray_Left
@onready var ray_right := $Ray_Right

@onready var label = $head/StateLabel3D

# collision shapes
enum collision_type {STANDING, CROUCHING, JUMPING}

@onready var standing_shape = $DefaultCollision
@onready var crouch_shape = $CrouchCollision
@onready var jump_shape = $JumpCollision

# input value
var input_dir := Vector2()
var input_speed := float()
var inputdir := Vector3()
var horizontal := float()
var vertical := float()

# player parameters
var gravity := 9.0
var jump_force := 6.0
const WALK_SPEED := 2.0
const RUN_SPEED := 6.0
const TURN_SPEED := 15
var move_speed : float
var strafe := false
var can_run := true

# physics values
var vertical_velocity : Vector3
var player_velocity = Vector3()
var direction : Vector3
var direction_velocity : Vector3
var normal_direction = Vector3()
var lean_velocity : Vector3
var last_lean_velocity : Vector3
var lean_acceleration : Vector3
var lean : Vector3
var rotation_transform : Transform3D
var root_velocity = Vector3()
var last_falling_velocity = float()
var last_input_strength = float()

var enable_root_motion = bool()
var jump_block = bool()
var disable_root_motion_y = bool()

# animationtree transition condition
var canmove : bool
var anim_isgrounded = bool(true)
var anim_landing_idle =bool()
var start_landing_idle =bool()

#animation state
var climb
var landing
var landing_end
var stop_move
var vault
var mantle
var jump
var idle
var move

var jump_button_pressed = false  # Flag to track jump button press
var jump_delay = 0.05  # Delay time in seconds

var currentspeed = Vector2.ZERO
var anim_acceleration = 8
var inputdir_speed = 1.0

#turn in place
var angle_diff = float()
var cam_angle_diff = float()
var strafe_angle = float()

var new_diff_angle = 0.0
var new_diff_angle_acceleration = 0.1

const SPEED = 15.0
const CROUCH_SPEED = 15.0
const SLIDE_SPEED = 25.0
const RUNSPEED = 25.0
const JUMP_VELOCITY = 20

var gravity_scale : float = 1.0

var current_input : Vector2
var current_velocity : Vector2

func _input(event):
	
	pass

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
	
	horizontal = Input.get_axis("left", "right")
	vertical = Input.get_axis("move_back", "move_forward")
	
	
	
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
	
