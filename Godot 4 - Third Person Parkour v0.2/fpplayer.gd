extends CharacterBody3D

@onready var head = $Head

#---------------CAMERA SETTINGS----------------
@export var pitch_min: float = -80.0
@export var pitch_max: float = 80.0
@export var mouse_sensitivity: float = 0.002

var y_angle: float = 0.0
var x_angle: float = 0.0

#---------------MOVEMENT SETTINGS----------------
const SPEED = 7.0
const JUMP_VELOCITY = 4.5
const GROUND_FRICTION = 2

var horiz_vel := Vector2(0, 0)
var verti_vel := Vector2(0, 0)

var ignore_next_mouse: bool = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	ignore_next_mouse = true

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		y_angle -= event.screen_relative.x * mouse_sensitivity
		x_angle += event.screen_relative.y * mouse_sensitivity
		x_angle = clamp(x_angle, deg_to_rad(pitch_min), deg_to_rad(pitch_max))
		
		rotation.y = y_angle
		head.rotation.x = x_angle
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(pitch_min), deg_to_rad(pitch_max))
		
		#print(head.rotation.x, rotation.y)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if is_on_floor():
		apply_friction(delta)
		player_movement(delta)
	if not is_on_floor():
		air_movement(delta)
		velocity += get_gravity() * delta

	move_and_slide()
	print(horiz_vel.length())

func _process(delta: float) -> void:
	pass

func player_movement(delta):
	var input_dir := Input.get_vector("right", "left", "backward", "forward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		horiz_vel.x = direction.x * SPEED
		horiz_vel.y = direction.z * SPEED
	else:
		horiz_vel.x = lerpf(horiz_vel.x, 0, .95)
		horiz_vel.y = lerpf(horiz_vel.y, 0, .95)
	
	velocity.x = lerpf(velocity.x, horiz_vel.x, .1)
	velocity.z = lerpf(velocity.z, horiz_vel.y, .1)

func air_movement(delta):
	var input_dir := Input.get_vector("right", "left", "backward", "forward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		horiz_vel.x = direction.x * SPEED * .80
		horiz_vel.y = direction.z * SPEED * .80
	
	velocity.x = lerpf(velocity.x, horiz_vel.x, .1)
	velocity.z = lerpf(velocity.z, horiz_vel.y, .1)

func apply_friction(delta):
	var speed = velocity.length()
	if speed == 0:
		return
	
	var drop = speed * GROUND_FRICTION * delta
	velocity *= max(speed - drop, 0) / speed
