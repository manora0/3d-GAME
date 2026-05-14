extends Control

@onready var gun_hand: AnimatedSprite2D = $CanvasLayer/"gun hand"
@onready var latch_hand: AnimatedSprite2D = $CanvasLayer/"latch hand"
@onready var dash_mark_1: AnimatedSprite2D = $CanvasLayer/"Dash Mark 1"
@onready var dash_mark_2: AnimatedSprite2D = $CanvasLayer/"Dash Mark 2"

@export var latch_hand_curve: Curve
@export var latch_hand_duration: float = 0.6
@export var muzzle_offset: Vector2 = Vector2(-80, -30)

@export var sway_strength: float = 0.06
@export var sway_max: Vector2 = Vector2(18, 10)
@export var sway_return_speed: float = 7.0
@export var recoil_offset: Vector2 = Vector2(22, 18)
@export var recoil_return_speed: float = 14.0
@export var move_sway_strength: float = 1.2
@export var move_sway_max: Vector2 = Vector2(14, 8)
@export var move_sway_lerp: float = 6.0

var _latch_hand_time := 0.0
var _latch_hand_playing := false

var _gun_material: ShaderMaterial
var _muzzle_light: PointLight2D
var _player: CharacterBody3D

const MAX_LATCH_GLOW_DIST := 30.0

var _gun_rest_pos: Vector2
var _sway_offset: Vector2 = Vector2.ZERO
var _move_sway_offset: Vector2 = Vector2.ZERO
var _recoil_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	gun_hand.sprite_frames.set_animation_loop("default", false)
	dash_mark_1.sprite_frames.set_animation_loop("default", false)

	gun_hand.animation_finished.connect(func(): gun_hand.frame = 0)
	dash_mark_1.animation_finished.connect(func(): dash_mark_1.frame = 0)
	dash_mark_2.animation_finished.connect(func(): dash_mark_2.frame = 0)

	_player = get_tree().get_first_node_in_group("player")
	if _player:
		_player.fired.connect(_on_fired)
		_player.latched.connect(_on_latched)
		_player.latch_regained.connect(_on_latch_regained)

	latch_hand.visible = false
	dash_mark_1.play()
	dash_mark_2.play()

	_gun_rest_pos = gun_hand.position
	_setup_muzzle_flash()

func _setup_muzzle_flash() -> void:
	var shader := preload("res://Scripts/muzzle_flash.gdshader")
	_gun_material = ShaderMaterial.new()
	_gun_material.shader = shader
	_gun_material.set_shader_parameter("tip_x", 1.0)
	gun_hand.material = _gun_material

	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var light_tex := GradientTexture2D.new()
	light_tex.gradient = gradient
	light_tex.fill = GradientTexture2D.FILL_RADIAL
	light_tex.fill_from = Vector2(0.5, 0.5)
	light_tex.fill_to = Vector2(1.0, 0.5)
	light_tex.width = 128
	light_tex.height = 128

	_muzzle_light = PointLight2D.new()
	_muzzle_light.texture = light_tex
	_muzzle_light.color = Color(1.0, 0.75, 0.2)
	_muzzle_light.energy = 0.0
	_muzzle_light.texture_scale = 1.0
	$CanvasLayer.add_child(_muzzle_light)

func _update_latch_glow() -> void:
	if _player == null:
		return
	var nearest_dist := MAX_LATCH_GLOW_DIST
	var nearest_pos := Vector3.ZERO
	var found := false
	for latch in get_tree().get_nodes_in_group("latch"):
		var d := _player.global_position.distance_to(latch.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest_pos = latch.global_position
			found = true
	if not found:
		_gun_material.set_shader_parameter("latch_intensity", 0.0)
		return
	var intensity := (1.0 - nearest_dist / MAX_LATCH_GLOW_DIST) * 1.5
	_gun_material.set_shader_parameter("latch_intensity", intensity)
	var viewport_size := get_viewport().get_visible_rect().size
	_gun_material.set_shader_parameter("gun_screen_uv", gun_hand.global_position / viewport_size)
	var camera := get_viewport().get_camera_3d()
	if camera and not camera.is_position_behind(nearest_pos):
		var screen_pos := camera.unproject_position(nearest_pos)
		_gun_material.set_shader_parameter("latch_screen_uv", screen_pos / viewport_size)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_sway_offset.x -= event.relative.x * sway_strength
		_sway_offset.y -= event.relative.y * sway_strength
		_sway_offset = _sway_offset.clamp(-sway_max, sway_max)

func _process(delta: float) -> void:
	if _latch_hand_playing:
		_latch_hand_time += delta
		var t = clamp(_latch_hand_time / latch_hand_duration, 0.0, 1.0)
		var progress = latch_hand_curve.sample(t) if latch_hand_curve else t
		var frame_count = latch_hand.sprite_frames.get_frame_count("default")
		latch_hand.frame = int(progress * (frame_count - 1))
		if t >= 1.0:
			_latch_hand_playing = false
			latch_hand.visible = false

	_sway_offset = _sway_offset.lerp(Vector2.ZERO, sway_return_speed * delta)
	_recoil_offset = _recoil_offset.lerp(Vector2.ZERO, recoil_return_speed * delta)

	if _player:
		var local_vel := _player.transform.basis.inverse() * _player.velocity
		var target := Vector2(-local_vel.x, local_vel.z) * move_sway_strength
		target = target.clamp(-move_sway_max, move_sway_max)
		_move_sway_offset = _move_sway_offset.lerp(target, move_sway_lerp * delta)

	var total_offset := _sway_offset + _move_sway_offset + _recoil_offset
	gun_hand.position = _gun_rest_pos + total_offset
	_muzzle_light.position = _gun_rest_pos + muzzle_offset + total_offset
	_update_latch_glow()

func _on_fired() -> void:
	gun_hand.stop()
	gun_hand.frame = 0
	gun_hand.play()
	_recoil_offset = recoil_offset
	_flash_muzzle()

func _flash_muzzle() -> void:
	_gun_material.set_shader_parameter("flash_intensity", 1.0)
	_muzzle_light.energy = 2.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_muzzle_light, "energy", 0.0, 0.12)
	tween.tween_method(
		func(v: float): _gun_material.set_shader_parameter("flash_intensity", v),
		1.0, 0.0, 0.12
	)

func _on_latched(charges: int) -> void:
	_latch_hand_time = 0.0
	_latch_hand_playing = true
	latch_hand.visible = true
	match charges:
		1:
			dash_mark_2.stop()
			dash_mark_2.frame = 1
		0:
			dash_mark_1.stop()
			dash_mark_1.frame = 1

func _on_latch_regained(charges: int) -> void:
	match charges:
		1:
			dash_mark_1.frame = 0
			dash_mark_1.play()
		2:
			dash_mark_2.frame = 0
			dash_mark_2.play()
