extends CharacterBody3D

signal fired
signal latched(charges: int)
signal latch_regained(charges: int)

#1152 x 648

const SCREEN_HEIGHT = 648.0
const SCREEN_WIDTH = 1152.0

#---------------CAMERA SETTINGS----------------

@onready var head := $Head
@onready var camera := $Head/Camera3D
@export var pitch_min: float = -80.0
@export var pitch_max: float = 80.0
@export var mouse_sensitivity: float = 0.002

var y_angle: float = 0.0
var x_angle: float = 0.0

#---------------MOVEMENT SETTINGS----------------
const MAX_SPEED := 7.0
const GROUND_ACCEL = 16
const GROUND_FRICTION = 10.0
const STOP_SPEED = 2.0
const AIR_ACCEL = 6
const AIR_WISH_SPEED_CAP = 5.0
const AIR_CONTROL = 50.0
const SPEED = 7.0
const JUMP_VELOCITY = 4.5

const STRAFE_LURCH_BLEND := 0.35
const STRAFE_LURCH_MIN_SPEED := 4.0

#--------------SLIDE SETTINGS-------------------

@export var slide_curve:Curve
@onready var slide_boost_timer: Timer = $Timers/SlideBoostTimer
const SLIDE_FRICTION := 0.5
const SLIDE_FRICTION_EASE_DURATION = 4.0
const SLIDE_DURATION := 1.5
const SLIDE_BOOST := 6.0
var can_boost := true

var is_sliding := false
var slide_timer := 0.0
var slide_direction := Vector3.ZERO

#----------------WALLRUN SETTINGS----------------

@onready var left_ray: RayCast3D = $Left
@onready var right_ray: RayCast3D = $Right
@onready var velocity_dir_ray: RayCast3D = $VelocityDir
const WALLRUN_GRAVITY := 2.0
const WALLRUN_TILT := 0.3
const WALLRUN_MAX_SPEED := 15.0
const WALLRUN_ACCEL := 10.0
const WALL_JUMP_HORIZONTAL := 8.0
const WALL_JUMP_VERTICAL := 5.5
const WALL_JUMP_DECAY_TIME := 0.5
const WALL_JUMP_MIN_SPEED := 10.0
const WALL_JUMP_BOOST := 12.0
var is_wallrunning := false
var wall_normal: Vector3 = Vector3.ZERO
var wallrun_side: String = "" # "left" "right
var wall_jump_timer := 0.0
var wall_jump_decel := 0.0

#------------------SHOOT SETTINGS----------------

const SHOOT_RANGE := 200.0
const SHOOT_COOLDOWN := 0.15
const MAX_BULLETS := 10
var bullet_count := MAX_BULLETS
var can_shoot := true
var bullet_trail_scene := preload("res://Scripts/BulletTrail.gd")

#------------------KICK SETTINGS-----------------

@onready var kick_leg: Node3D = $KickLeg
@onready var stand_collision: CollisionShape3D = $CollisionShape3D
@onready var slide_collision: CollisionShape3D = $SlideCollision
@onready var kick_cast: ShapeCast3D = $KickLeg/KickCast
var is_kicking := false
const KICK_EXTENDED_POSITION := 1.5
const KICK_RETRACTED_POSITION := 0.0
const KICK_COOLDOWN := 0.8
var kick_tween: Tween
var can_kick := true

#-----------------LATCH SETTINGS-----------------

@onready var latch_cursor: Node3D = $LatchCursor
@onready var cursor_cast: RayCast3D = $CursorCast
@export var latch_curve: Curve

## Base offset for the beam start, in camera-local space (right, up, forward).
@export var beam_origin_offset: Vector3 = Vector3(0.25, -0.2, 0.0)
## AnimatedSprite2D showing the hand — used to look up per-frame offsets below.
@export var beam_hand_sprite: AnimatedSprite2D
## Per-frame additional offsets in camera-local space (right, up, forward).
## Index matches the sprite frame number. Extend the array to cover all frames.
@export var beam_frame_offsets: Array[Vector3] = []

const MAX_CAST_DISTANCE := 30.0
const MAX_CAST_COUNT := 2
var latch_cast_count := 2
var can_refresh := true
var is_latching := false

var latch_start_pos: Vector3
var latch_initial_dist: float
var latch_end_pos: Vector3
const LATCH_SPEED = 30

var latch_pending := false
var latch_pending_pos: Vector3

var latch_beam_mesh: MeshInstance3D

#---------------DOUBLE JUMP--------------

var can_jump = true
var can_double_jump = true

var horiz_vel := Vector2(0, 0)
var verti_vel := Vector2(0, 0)

var jump_delta_time = 0.0

var ignore_next_mouse: bool = false

var prev_strafe_input := 0.0
var was_on_floor := false

var latch_penalty_timer := 0.0
const LATCH_ACCEL_PENALTY_DURATION := .25
const LATCH_ACCEL_PENALTY_FACTOR := 0.1

#-------------UI SETTINGS------------------

@onready var velocity_label = $Control/VelocityLabel
@onready var latch_label = $Control/LatchLabel

var kick_rest_pos: Vector3

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	ignore_next_mouse = true
	slide_boost_timer.timeout.connect(slide_boost_switch)
	kick_rest_pos = kick_leg.position
	_setup_latch_beam()

func _setup_latch_beam():
	latch_beam_mesh = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.06
	cyl.bottom_radius = 0.06
	cyl.height = 1.0
	latch_beam_mesh.mesh = cyl

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.75, 0.1, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.75, 0.1, 1.0)
	mat.emission_energy_multiplier = 4.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.85
	latch_beam_mesh.material_override = mat
	latch_beam_mesh.visible = false
	add_child(latch_beam_mesh)

func _get_hand_pos() -> Vector3:
	var offset := beam_origin_offset
	if beam_hand_sprite and beam_frame_offsets.size() > beam_hand_sprite.frame:
		offset += beam_frame_offsets[beam_hand_sprite.frame]
	return camera.global_position \
		+ camera.global_basis.x * offset.x \
		+ camera.global_basis.y * offset.y \
		+ camera.global_basis.z * offset.z

func _update_latch_beam_visuals() -> void:
	var active := is_latching or latch_pending
	if not active:
		latch_beam_mesh.visible = false
		return

	var hand_pos := _get_hand_pos()
	var target_pos := latch_end_pos if is_latching else latch_pending_pos
	var diff := target_pos - hand_pos
	var dist := diff.length()
	if dist < 0.05:
		latch_beam_mesh.visible = false
		return

	latch_beam_mesh.visible = true
	var dir := diff / dist
	var right_vec: Vector3
	if abs(dir.dot(Vector3.UP)) < 0.99:
		right_vec = dir.cross(Vector3.UP).normalized()
	else:
		right_vec = dir.cross(Vector3.FORWARD).normalized()
	var fwd_vec := right_vec.cross(dir).normalized()
	var r := 0.025
	var scaled_basis := Basis(right_vec * r, dir * dist, fwd_vec * r)
	latch_beam_mesh.global_transform = Transform3D(scaled_basis, hand_pos + diff * 0.5)
	

func restart_game() -> void:
	get_tree().reload_current_scene()

func _input(event):
	if Input.is_action_just_pressed("restart"):
		restart_game()
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		y_angle -= event.screen_relative.x * mouse_sensitivity
		x_angle += event.screen_relative.y * mouse_sensitivity
		x_angle = clamp(x_angle, deg_to_rad(pitch_min), deg_to_rad(pitch_max))
		
		rotation.y = y_angle
		head.rotation.x = x_angle
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(pitch_min), deg_to_rad(pitch_max))
		
	if Input.is_action_just_pressed("slide") and (is_latching or latch_pending):
		is_latching = false
		latch_pending = false
	if Input.is_action_just_pressed("slide") and is_on_floor() and not is_sliding:
		start_slide()
	if not Input.is_action_pressed("slide"):
		stop_slide()
	if Input.is_action_just_pressed("kick") and can_kick:
		kick()
	if Input.is_action_just_pressed("shoot") and can_shoot:
		shoot()
	
	
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor() and can_jump:
		velocity.y += JUMP_VELOCITY
		can_jump = false
	if Input.is_action_just_pressed("jump") and not is_on_floor() and can_double_jump and not is_wallrunning:
		can_double_jump = false
		if is_latching:
			is_latching = false
			can_double_jump = true
		double_jump(delta)
		
	
	if not is_on_floor() and not is_wallrunning:
		velocity += get_gravity() * delta
	
	var input_dir := Input.get_vector("right", "left", "backward", "forward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	latch_cast_cursor()

	if is_kicking:
		kick_impulse()

	if Input.is_action_just_pressed("latch"):
		latch_ask(delta)
	if is_latching:
		latch_ask(delta)
	
	if is_on_floor() and not was_on_floor and Input.is_action_pressed("slide") and not is_sliding:
		start_slide()

	if is_on_floor() and not is_latching:
		if not can_double_jump or not can_jump:
			can_jump = true
			can_double_jump = true
		is_wallrunning = false
		if is_sliding:
			slide(delta)
		else:
			if direction == Vector3.ZERO:
				stop_friction(delta, direction)
			else:
				pull_friction(delta, direction)
		player_movement(direction, delta)
		camera_bump()
	if not is_on_floor() and not is_latching:
		air_movement(direction, delta)
		strafe_lurch(direction)
		wallrun_check(delta, direction)
		if wall_jump_timer > 0:
			wall_jump_timer -= delta
			if direction == Vector3.ZERO:
				var h_speed = Vector2(velocity.x, velocity.z).length()
				if h_speed > 0:
					var new_speed = max(h_speed - wall_jump_decel * delta, 0.0)
					velocity.x = velocity.x / h_speed * new_speed
					velocity.z = velocity.z / h_speed * new_speed
		
	if not is_sliding and slide_collision.disabled == false and can_stand():
		set_slide_collision(false)

	if latch_penalty_timer > 0:
		latch_penalty_timer -= delta
		if not is_on_floor() and not is_latching:
			var h_speed = Vector2(velocity.x, velocity.z).length()
			if h_speed > 0:
				var drag = 1.0 - LATCH_ACCEL_PENALTY_FACTOR
				var new_speed = max(h_speed - drag * h_speed * delta * 3.0, 0.0)
				velocity.x = velocity.x / h_speed * new_speed
				velocity.z = velocity.z / h_speed * new_speed
	elif latch_pending:
		latch_pending = false
		is_latching = true
		latch_start_pos = global_position
		latch_initial_dist = global_position.distance_to(latch_pending_pos)
		latch_end_pos = latch_pending_pos

	was_on_floor = is_on_floor()
	move_and_slide()

func _process(delta: float) -> void:
	update_velocity_label()
	_update_latch_beam_globals()
	_update_latch_beam_visuals()
	if is_wallrunning:
		var side = wall_normal.dot(global_basis.x)
		head.rotation.z = lerp(head.rotation.z, -side * WALLRUN_TILT, 10.0 * delta)
	else:
		head.rotation.z = lerp(head.rotation.z, 0.0, 10.0 * delta)
	
#region ACCELERATION

func player_movement(direction: Vector3, delta):
	var current_speed = velocity.dot(direction)
	var add_speed = MAX_SPEED - current_speed
	
	if add_speed <= 0:
		return
	
	var penalty = LATCH_ACCEL_PENALTY_FACTOR if latch_penalty_timer > 0 else 1.0
	var accel_speed = GROUND_ACCEL * delta * MAX_SPEED * penalty

	velocity += accel_speed * direction


func air_movement(direction: Vector3, delta):
	var wish_vel = direction * MAX_SPEED
	var wish_dir = wish_vel.normalized()
	var wish_spd = min(wish_vel.length(), AIR_WISH_SPEED_CAP)

	var current_speed = velocity.dot(wish_dir)
	var add_speed = wish_spd - current_speed

	if add_speed <= 0: return

	var penalty = LATCH_ACCEL_PENALTY_FACTOR if latch_penalty_timer > 0 else 1.0
	var accel_speed = AIR_ACCEL * wish_spd * delta * penalty
	accel_speed = min(accel_speed, add_speed)

	velocity += accel_speed * wish_dir
	#air_control(direction, delta)

func air_control(direction: Vector3, delta):
	if direction == Vector3.ZERO:
		return
	
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	if horizontal_speed == 0:
		return
	
	var wish_dir = direction.normalized()

	var forward_factor = abs(wish_dir.dot(Vector3(0, 0, -1).rotated(Vector3.UP, rotation.y)))
	
	var dot = velocity.normalized().dot(wish_dir)
	dot = clamp(dot, -1.0, 1.0)
	
	# zspeed stores horizontal speed before control
	var zspeed = horizontal_speed
	
	# rotate velocity toward wish direction
	var turn_amount = AIR_CONTROL * dot * dot * delta
	
	var horizontal_vel = Vector3(velocity.x, 0, velocity.z).normalized()
	horizontal_vel = horizontal_vel.lerp(wish_dir, turn_amount).normalized()
	
	# reapply horizontal speed after turning
	velocity.x = horizontal_vel.x * zspeed
	velocity.z = horizontal_vel.z * zspeed
	
#endregion

#region FRICTION

func stop_friction(delta, direction):
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	if horizontal_speed == 0:
		return
	
	var control = max(horizontal_speed, STOP_SPEED)
	var drop = control * GROUND_FRICTION * delta
	
	var new_speed = max(horizontal_speed - drop, 0) / horizontal_speed
	velocity.x *= new_speed
	velocity.z *= new_speed

func pull_friction(delta, direction):
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	if horizontal_speed == 0 or horizontal_speed <= MAX_SPEED:
		return

	var over_speed = horizontal_speed - MAX_SPEED
	var drop = over_speed * GROUND_FRICTION * delta
	var new_speed = max(horizontal_speed - drop, 0) / horizontal_speed
	
	velocity.x *= new_speed
	velocity.z *= new_speed

#endregion

#region SLIDE

func set_slide_collision(sliding: bool):
	stand_collision.disabled = sliding
	slide_collision.disabled = not sliding

func can_stand() -> bool:
	stand_collision.disabled = false
	slide_collision.disabled = true
	var blocked = test_move(global_transform, Vector3.ZERO)
	stand_collision.disabled = true
	slide_collision.disabled = false
	return not blocked

func stop_slide():
	if not is_sliding:
		return
	is_sliding = false
	if can_stand():
		set_slide_collision(false)

func start_slide():
	slide_timer = 0
	is_sliding = true
	set_slide_collision(true)
	if !can_boost: return
	var horizontal = Vector2(velocity.x, velocity.z)
	var direction = Vector3(velocity.x, 0, velocity.z).normalized()
	var boost_speed = SLIDE_BOOST
	
	if abs(horizontal.length()) >= (MAX_SPEED + SLIDE_BOOST):
		boost_speed = 0
	elif horizontal.length() > MAX_SPEED:
		boost_speed -= horizontal.length() - MAX_SPEED
	velocity += direction * (boost_speed)
	slide_boost_switch(false)
	
func slide(delta):
	if not is_sliding:
		return

	slide_timer += delta
	var progress = clamp(slide_timer / SLIDE_FRICTION_EASE_DURATION, 0.0, 1.0)
	
	var curve_value = slide_curve.sample(progress)
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	
	var friction = SLIDE_FRICTION * curve_value
	var drop = horizontal_speed * friction * delta
	var new_speed = max(horizontal_speed - drop, 0)
	
	if horizontal_speed > 0:
		velocity.x = velocity.x / horizontal_speed * new_speed
		velocity.z = velocity.z / horizontal_speed * new_speed
		
	if new_speed < 5.0:
		stop_slide()

func camera_bump():
	if is_sliding:
		head.position.y = move_toward(head.position.y, .5, .1)
	else:
		head.position.y = move_toward(head.position.y, 1, .1)

func slide_boost_switch(control = true):
	if control:
		can_boost = true
	else: 
		can_boost = false
		slide_boost_timer.start()

#endregion

#region WALLRUN
	
func is_wall(cast: RayCast3D) -> bool:
	if not cast.is_colliding():
		return false
	return abs(cast.get_collision_normal().dot(Vector3.UP)) < 0.3
	
func get_slide_wall_normal() -> Vector3:
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var normal = col.get_normal()
		if abs(normal.dot(Vector3.UP)) < 0.3:
			return normal
	return Vector3.ZERO

func wallrun_check(delta, direction):
	if velocity.length() > .1:
		velocity_dir_ray.target_position = velocity.normalized() * 1.5

	var on_wall_rh  = is_wall(right_ray)
	var on_wall_lh  = is_wall(left_ray)
	var on_wall_vel = is_wall(velocity_dir_ray)
	var slide_normal = get_slide_wall_normal()
	var on_wall_slide = slide_normal != Vector3.ZERO

	if not is_on_floor() and (on_wall_rh or on_wall_lh or on_wall_vel or on_wall_slide):
		var just_entered = not is_wallrunning
		if just_entered:
			is_wallrunning = true
			can_double_jump = true
			velocity.y = max(velocity.y, 3.0)
			if on_wall_slide:
				wall_normal = slide_normal
			elif on_wall_vel:
				wall_normal = velocity_dir_ray.get_collision_normal()
			elif on_wall_lh:
				wall_normal = left_ray.get_collision_normal()
			else:
				wall_normal = right_ray.get_collision_normal()

		var along_wall = wall_normal.cross(Vector3.UP).normalized()
		var horizontal_vel = Vector3(velocity.x, 0, velocity.z)
		if along_wall.dot(horizontal_vel) < 0:
			along_wall = -along_wall

		if just_entered:
			var h_speed = horizontal_vel.length()
			velocity.x = along_wall.x * h_speed
			velocity.z = along_wall.z * h_speed
		else:
			var projected = along_wall * horizontal_vel.dot(along_wall)
			velocity.x = projected.x
			velocity.z = projected.z
		velocity.y += Vector3.DOWN.y * WALLRUN_GRAVITY * delta

		var input_dir := Input.get_vector("right", "left", "backward", "forward")
		var h_speed = Vector2(velocity.x, velocity.z).length()
		if input_dir != Vector2.ZERO and h_speed < WALLRUN_MAX_SPEED:
			var add = min(WALLRUN_ACCEL * delta, WALLRUN_MAX_SPEED - h_speed)
			velocity.x += along_wall.x * add
			velocity.z += along_wall.z * add
		elif h_speed > WALLRUN_MAX_SPEED:
			var new_speed = move_toward(h_speed, WALLRUN_MAX_SPEED, 4 * delta)
			velocity.x = velocity.x / h_speed * new_speed
			velocity.z = velocity.z / h_speed * new_speed
		
		var active_ray = left_ray if on_wall_lh else right_ray
		if active_ray.is_colliding():
			var hit_point = active_ray.get_collision_point()
			var target_pos = Vector3(hit_point.x, global_position.y, hit_point.z) + wall_normal * 0.5
			global_position = global_position.lerp(target_pos, 10.0 * delta)
		
		if Input.is_action_just_pressed("jump"):
			velocity += wall_normal * WALL_JUMP_HORIZONTAL
			velocity.y = WALL_JUMP_VERTICAL
			h_speed = Vector2(velocity.x, velocity.z).length()
			if h_speed < WALL_JUMP_MIN_SPEED:
				var boost_dir = Vector3(velocity.x, 0, velocity.z).normalized()
				velocity.x = boost_dir.x * WALL_JUMP_BOOST
				velocity.z = boost_dir.z * WALL_JUMP_BOOST
			wall_jump_decel = Vector2(velocity.x, velocity.z).length() / WALL_JUMP_DECAY_TIME
			wall_jump_timer = WALL_JUMP_DECAY_TIME
			is_wallrunning = false
			left_ray.enabled = false
			right_ray.enabled = false
			velocity_dir_ray.enabled = false
			get_tree().create_timer(.2).timeout.connect(func():
				left_ray.enabled = true
				right_ray.enabled = true
				velocity_dir_ray.enabled = true
			)
		
	else:
		is_wallrunning = false

#endregion

#region KICK 

func kick():
	if kick_tween:
		kick_tween.kill()
		kick_leg.position = kick_rest_pos
	can_kick = false
	is_kicking = true
	var target: Vector3
	if latch_cursor.visible:
		target = latch_cursor.global_position
	else:
		target = camera.global_position + (-camera.global_basis.z) * MAX_CAST_DISTANCE
	var kick_dir = global_basis.inverse() * (target - kick_leg.global_position).normalized()
	var extended_pos = kick_rest_pos + kick_dir * KICK_EXTENDED_POSITION
	kick_tween = create_tween()
	kick_tween.tween_property(kick_leg, "position", extended_pos, 0.05)
	kick_tween.tween_interval(0.2)
	kick_tween.tween_property(kick_leg, "position", kick_rest_pos, 0.3)
	kick_tween.tween_callback(func(): is_kicking = false)
	get_tree().create_timer(KICK_COOLDOWN).timeout.connect(func(): can_kick = true)

func kick_impulse():
	if not kick_cast.is_colliding():
		return
	var collider := kick_cast.get_collider(0)
	print(collider.get_groups())
	if collider.is_in_group("latch") or collider.get_parent().is_in_group("latchw"):
		if latch_cast_count < MAX_CAST_COUNT:
			latch_cast_count += 1
			latch_regained.emit(latch_cast_count)
		is_kicking = false
		return
	var normal = kick_cast.get_collision_normal(0)
	velocity = velocity.reflect(normal)
	is_kicking = false
#endregion

#region SHOOT

func shoot():
	if bullet_count <= 0:
		return
	bullet_count -= 1
	can_shoot = false
	fired.emit()
	get_tree().create_timer(SHOOT_COOLDOWN).timeout.connect(func(): can_shoot = true)

	var dir = -camera.global_basis.z
	var gun_screen_pos := Vector2(830, 353)
	var origin = camera.project_ray_origin(gun_screen_pos) + camera.project_ray_normal(gun_screen_pos) * 0.5
	var to = camera.global_position + dir * SHOOT_RANGE

	var query := PhysicsRayQueryParameters3D.create(origin, to)
	query.exclude = [self]
	var result = get_world_3d().direct_space_state.intersect_ray(query)

	var hit_pos = result.position if result else to
	if result:
		var target_node: Node = null
		if result.collider.is_in_group("target"):
			target_node = result.collider
		elif result.collider.get_parent().is_in_group("target"):
			target_node = result.collider.get_parent()
		if target_node:
			if latch_cast_count < MAX_CAST_COUNT:
				latch_cast_count += 1
				latch_regained.emit(latch_cast_count)
			if target_node.has_method("on_shot"):
				target_node.on_shot()

	var trail := MeshInstance3D.new()
	trail.set_script(bullet_trail_scene)
	get_tree().root.add_child(trail)
	trail.init(origin, hit_pos)

#endregion

#region LATCH

func latch_cast_cursor():
	var origin = camera.project_ray_origin(Vector2(SCREEN_WIDTH/2, SCREEN_HEIGHT/2))
	var direction = camera.project_ray_normal(Vector2(SCREEN_WIDTH/2, SCREEN_HEIGHT/2))
	var to = origin + direction * MAX_CAST_DISTANCE
	var query := PhysicsRayQueryParameters3D.create(origin, to)
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	
	if result:
		latch_cursor.show()
		latch_cursor.global_position = result.position
	else:
		latch_cursor.hide()

func latch_ask(delta: float):
	if not is_latching and not latch_pending and latch_cursor.visible:
		if latch_cast_count <= 0:
			return
		latch_cast_count -= 1
		latched.emit(latch_cast_count)
		latch_pending = true
		latch_pending_pos = latch_cursor.global_position
		latch_penalty_timer = LATCH_ACCEL_PENALTY_DURATION
	
	if not is_latching:
		return

	var current_dist = global_position.distance_to(latch_end_pos)
	var progress = clamp(1.0 - (current_dist / latch_initial_dist), 0.0, 1.0)

	if current_dist < 0.5 or progress > .85:
		is_latching = false
		return

	var speed = latch_curve.sample(progress) * LATCH_SPEED
	var latch_dir = (latch_end_pos - global_position).normalized()
	
	velocity.x = latch_dir.x * speed
	velocity.y = latch_dir.y * speed
	velocity.z = latch_dir.z * speed
	
#endregion

func _update_latch_beam_globals() -> void:
	var active = is_latching or latch_pending
	RenderingServer.global_shader_parameter_set("latch_beam_intensity", 1.5 if active else 0.0)
	if active:
		var end_pos = latch_end_pos if is_latching else latch_pending_pos
		RenderingServer.global_shader_parameter_set("latch_beam_start", _get_hand_pos())
		RenderingServer.global_shader_parameter_set("latch_beam_end", end_pos)

#region UI

func update_velocity_label():
	var text = """
	Dash Count: %s
	Bullets: %s/%s
	Velocity: %s
	Can Double Jump: %s
	"""
	latch_label.text = text % [str(latch_cast_count), str(bullet_count), str(MAX_BULLETS), str(snapped(Vector2(velocity.x, velocity.z).length(), 0.01)), str(can_double_jump)]
	#latch_label.text = "Dash Count: " + str(latch_cast_count)
	#velocity_label.text = "Veloicty: " + str(snapped(Vector2(velocity.x, velocity.z).length(), 0.01))

#endregion

@export var jump_curve: Curve
var jump_force = 4.5
var jump_max_force = 14

func double_jump(delta):
	print('jumped')
	var horizontal = Vector2(velocity.x, velocity.z).length()
	var applied_force: float 
	if velocity.y >= 0.0:
		var difference = jump_force - velocity.y 
		applied_force = max(difference, 0.0)
	else:
		velocity.y = 0
		applied_force = jump_force
	
	var position = horizontal / (MAX_SPEED * 2)
	var scale = jump_curve.sample(position)
	
	applied_force *= scale
	velocity.y += applied_force 

const STRAFE_LURCH_WINDOW = 1.0
var strafe_lurch_timer = 0.0


func strafe_lurch(direction: Vector3):
	if direction == Vector3.ZERO:
		return

	var input = Input.get_vector("right", "left", "backward", "forward")
	var strafe = input.x

	# Only trigger on a fresh strafe press, not while held
	var just_strafed = abs(strafe) > 0.2 and abs(prev_strafe_input) <= 0.2
	prev_strafe_input = strafe

	if not just_strafed:
		return

	var h_vel = Vector3(velocity.x, 0, velocity.z)
	var h_speed = h_vel.length()

	if h_speed < STRAFE_LURCH_MIN_SPEED:
		return

	# Redirect horizontal velocity toward the strafe direction, preserving speed
	var new_dir = h_vel.normalized().lerp(direction.normalized(), STRAFE_LURCH_BLEND).normalized()
	velocity.x = new_dir.x * h_speed
	velocity.z = new_dir.z * h_speed
