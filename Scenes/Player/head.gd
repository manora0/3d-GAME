extends Node3D

@export var player : Player


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

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
	player.rotate_y(vector.x * .001)
	var clamped = clamp(self.rotation.x + vector.y * .001, -1.5, 1.5)
	self.rotation.x = clamped
