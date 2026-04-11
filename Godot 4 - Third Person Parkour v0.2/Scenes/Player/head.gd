extends Node3D

@export var player : Player

var body_can_rotate : bool = true
var camera_can_rotate : bool = true

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if body_can_rotate:
			rotate_body(event.relative)
		elif camera_can_rotate:
			rotate_camera(event.relative)
	if(event is InputEventKey and event.is_pressed() and not event.is_echo()):
		if(event.shift_pressed && event.keycode == KEY_R):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if(event is InputEventMouseButton):
		if(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			

func rotate_body(vector: Vector2) -> void:
	player.rotate_y(vector.x * -.001)
	var clamped = clamp(self.rotation.x + vector.y * .001, -1.5, 1.5)
	self.rotation.x = clamped

func rotate_camera(vector: Vector2) -> void:
	player.head.rotate_y(vector.x * -.001)
	var clamped = clamp(self.rotation.x + vector.y * .001, -1.5, 1.5)
	self.rotation.x = clamped

func lock_cam(status : bool):
	camera_can_rotate = status
	
func lock_body(status : bool):
	if status:
		player.global_rotation.y = player.head.global_rotation.y
		player.head.rotation.y = 0
	body_can_rotate = status
