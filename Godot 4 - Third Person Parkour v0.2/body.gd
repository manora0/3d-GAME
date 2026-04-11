extends Node3D
#
#@export var pitch_min: float = -80.0
#@export var pitch_max: float = 80.0
#@export var mouse_sensitivity: float = 0.002
#
#
#var y_angle: float = 0.0
#var x_angle: float = 0.0
#
#func _ready():
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
#
#func _input(event):
	#if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		#y_angle += event.relative.x * mouse_sensitivity
		#x_angle += event.relative.y * mouse_sensitivity
#
#
#func _process(delta):
#
	## rotation.x = lerpf(clamp(rotation.x, deg_to_rad(pitch_min), deg_to_rad(pitch_max)),
	## 	x_angle, delta * 10)
	#rotation.x = lerpf(rotation.x, x_angle, delta * 10)
	#rotation.y = lerpf(rotation.y, y_angle, delta * 10)
	#
	#if Input.is_key_pressed(KEY_ESCAPE):
		#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#
	#if Input.is_action_just_pressed("ui_accept") and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
