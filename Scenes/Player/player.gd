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
@onready var ray_on_ground := $RayOnGroundCheck

# collision shapes
enum collision_type {STANDING, CROUCHING, JUMPING}

@onready var standing_shape = $DefaultCollision
@onready var crouch_shape = $CrouchCollision
@onready var jump_shape = $JumpCollision

@onready var camera_parent = get_parent().get_node("Camera")
@onready var camera_target = get_parent().get_node("Camera").get_node("CameraTarget")
var camera_T  = float()
var camera_offset : Vector3 = Vector3(0,2.5,0)

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
var anim_isgrounded := true
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

const SPEED = 10
const CROUCH_SPEED = 7.0
const SLIDE_SPEED = 13.0
const RUNSPEED = 15.0
const JUMP_VELOCITY = 20

var gravity_scale : float = 1.0

var current_input : Vector2
var current_velocity : Vector2

func _input(event):
	#if Input.is_action_just_pressed("sprint") and !(climb or vault or mantle or stop_move):
		#can_run = !can_run
#
	#if Input.is_action_just_pressed("strafe"):
		#strafe = !strafe
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
	if state_machine.current_state:
		state_machine.current_state.Update(delta)
	
	animation_parameter()
	
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
		anim.play("d/Dance")
		

func rotate_player(delta: float):
	if direction != Vector3.ZERO:
		var target_angle = Vector3.BACK.signed_angle_to(direction, Vector3.UP)
		rotation.y = lerp_angle(rotation.y, target_angle, TURN_SPEED * delta)


func set_camera_follow(delta: float):
	var cam_timer = clamp(delta * 300 / 20, 0,1)
	camera_parent.global_transform.origin = camera_parent.global_transform.origin.lerp(self.global_transform.origin + camera_offset, cam_timer)
	pass

func _physics_process(delta: float) -> void:
	camera_T = camera_target.global_transform.basis.get_euler().y
	horizontal = Input.get_axis("move_left", "move_right")
	vertical = Input.get_axis("move_forward", "move_back")
	inputdir = Vector3(horizontal, 0, vertical).normalized()
	
	if not is_on_floor():
		velocity += get_gravity() * delta * 4  * gravity_scale
	
	#lean_toward_acceleration(delta)
	rotate_player(delta)
	onground_check()
	set_camera_follow(delta)
	
	rotation.y = lerp_angle(rotation.y, camera_T, delta * TURN_SPEED)
	
	if state_machine.current_state:
		state_machine.current_state.Physics_Update(delta)
	
	
	move_and_slide()
	
func lean_toward_acceleration(delta: float):
	if anim_isgrounded:
		if direction != Vector3.ZERO:
			lean_velocity = lean_velocity.lerp(direction * move_speed, 3 * delta)
		else:
			lean_velocity = lean_velocity.lerp(Vector3.ZERO, 3 * delta)
	
	lean_acceleration = lean_velocity - last_lean_velocity
	lean = lean_acceleration.cross(Vector3.UP) * 1.1
	player.rotation = lerp(player.rotation, -lean , 4 * delta)
	last_lean_velocity = lean_velocity

func onground_check():
	anim_isgrounded = ray_on_ground.is_colliding()

func animation_parameter():
	animationtree.set("parameters/StateMachine/conditions/idle", !canmove)
	animationtree.set("parameters/StateMachine/conditions/startmove", canmove)

	animationtree.set("parameters/StateMachine/conditions/isgrounded",anim_isgrounded)
	animationtree.set("parameters/StateMachine/conditions/isnotgrounded", !anim_isgrounded)

	animationtree.set("parameters/conditions/landing_idle", anim_landing_idle)
	animationtree.set("parameters/conditions/landing_move", !anim_landing_idle)

	animationtree.set("parameters/conditions/isgrounded_idle", start_landing_idle)
	animationtree.set("parameters/conditions/isgrounded_move", !start_landing_idle)












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
	
