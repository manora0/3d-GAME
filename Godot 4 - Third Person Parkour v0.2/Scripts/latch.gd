extends StaticBody3D

@onready var sprite_3d: AnimatedSprite3D = $CanvasLayer/AnimatedSprite3D
@onready var sphere_mesh: MeshInstance3D = $MeshInstance3D

var canvas_layer: CanvasLayer
var sprite_2d: AnimatedSprite2D
var omni_light: OmniLight3D
var glow_material: ShaderMaterial

const PULSE_SPEED := 2.0
const PULSE_DEPTH := 0.35
const LIGHT_ENERGY_BASE := 3.5
const LIGHT_ENERGY_RANGE := 1.8

func _ready():
	call_deferred("_setup_sprite")
	_setup_glow()

func _setup_glow():
	glow_material = ShaderMaterial.new()
	glow_material.shader = load("res://Scripts/latch_glow.gdshader")
	sphere_mesh.material_override = glow_material

	omni_light = OmniLight3D.new()
	omni_light.light_color = Color(0.85, 0.2, 1.0)
	omni_light.light_energy = LIGHT_ENERGY_BASE
	omni_light.omni_range = 6.0
	omni_light.omni_attenuation = 1.5
	omni_light.shadow_enabled = true
	add_child(omni_light)

func _setup_sprite():
	sprite_3d.hide()

	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 1
	get_tree().root.add_child(canvas_layer)

	sprite_2d = AnimatedSprite2D.new()
	sprite_2d.sprite_frames = sprite_3d.sprite_frames
	sprite_2d.speed_scale = sprite_3d.speed_scale
	canvas_layer.add_child(sprite_2d)
	sprite_2d.play("default")

func _process(delta):
	var pulse := sin(Time.get_ticks_msec() * 0.001 * PULSE_SPEED) * 0.5 + 0.5
	pulse = pulse * PULSE_DEPTH + (1.0 - PULSE_DEPTH)
	omni_light.light_energy = (LIGHT_ENERGY_BASE + LIGHT_ENERGY_RANGE * (pulse - 0.5) * 2.0)

	var camera := get_viewport().get_camera_3d()
	if camera == null or not is_instance_valid(sprite_2d):
		return

	if camera.is_position_behind(global_position):
		sprite_2d.visible = false
		return

	sprite_2d.visible = true
	sprite_2d.position = camera.unproject_position(global_position)

	var dist := global_position.distance_to(camera.global_position)
	var scale_factor = 7.0 / max(dist, 0.1)
	sprite_2d.scale = Vector2(scale_factor, scale_factor)

func _exit_tree():
	if is_instance_valid(canvas_layer):
		canvas_layer.queue_free()
