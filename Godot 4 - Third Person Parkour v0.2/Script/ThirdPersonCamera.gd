extends Node3D

@export var camera_target : Node3D
@export var pitch_max = 50 
@export var pitch_min = -50
var yaw = float()
var pitch = float()
var yaw_sensitivity = .002
var pitch_sensitivity = .002


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() != 0:
		yaw += -event.relative.x * yaw_sensitivity
		pitch += event.relative.y * pitch_sensitivity


func _physics_process(delta):
	camera_target.rotation.y = lerpf(camera_target.rotation.y, yaw, delta * 10)
	camera_target.rotation.x = lerpf(camera_target.rotation.x, pitch, delta * 10)

	pitch = clamp(pitch, deg_to_rad(pitch_min), deg_to_rad(pitch_max))

	#gamepad setting
	var cam_input_x = Input.get_axis("lookright", "lookleft")
	var cam_input_y = Input.get_axis("lookdown", "lookup")
	var camerainput = Vector2(cam_input_x,cam_input_y)
	
	yaw += camerainput.x * yaw_sensitivity * 30
	pitch += camerainput.y * pitch_sensitivity * 20
	
