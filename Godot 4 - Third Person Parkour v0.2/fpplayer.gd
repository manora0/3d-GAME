extends CharacterBody3D

@onready var head = $Head


#---------------CAMERA SETTINGS----------------
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
const AIR_ACCEL = 4
const AIR_WISH_SPEED_CAP = 6
const AIR_CONTROL = 50.0
const SPEED = 7.0
const JUMP_VELOCITY = 4.5

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
const WALL_JUMP_HORIZONTAL := 8.0
const WALL_JUMP_VERTICAL := 5.5
const WALL_JUMP_DECAY_TIME := 0.5
var is_wallrunning := false
var wall_normal: Vector3 = Vector3.ZERO
var wallrun_side: String = "" # "left" "right
var wall_jump_timer := 0.0
var wall_jump_decel := 0.0

#------------------KICK SETTINGS-----------------

@onready var kick_leg: Node3D = $KickLeg
@onready var kick_collision: CollisionShape3D = $KickLeg/StaticBody3D/CollisionShape3D
@onready var kick_cast: ShapeCast3D = $KickLeg/KickCast
var is_kicking := false
const KICK_EXTENDED_POSITION := 1.5
const KICK_RETRACTED_POSITION := 0.0
var kick_tween: Tween

var horiz_vel := Vector2(0, 0)
var verti_vel := Vector2(0, 0)

var ignore_next_mouse: bool = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	ignore_next_mouse = true
	slide_boost_timer.timeout.connect(slide_boost_switch)
	

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		y_angle -= event.screen_relative.x * mouse_sensitivity
		x_angle += event.screen_relative.y * mouse_sensitivity
		x_angle = clamp(x_angle, deg_to_rad(pitch_min), deg_to_rad(pitch_max))
		
		rotation.y = y_angle
		head.rotation.x = x_angle
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(pitch_min), deg_to_rad(pitch_max))
		
	if Input.is_action_just_pressed("slide") and is_on_floor() and not is_sliding:
		start_slide()
	if not Input.is_action_pressed("slide"):
		is_sliding = false
	if Input.is_action_just_pressed("kick"):
		kick()
	
	
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	if not is_on_floor() and not is_wallrunning:
		velocity += get_gravity() * delta
	
	var input_dir := Input.get_vector("right", "left", "backward", "forward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	
	if is_kicking:
		kick_impulse()
		
	if is_on_floor():
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
	if not is_on_floor():
		air_movement(direction, delta)
		wallrun_check(delta, direction)
		if wall_jump_timer > 0:
			wall_jump_timer -= delta
			if direction == Vector3.ZERO:
				var h_speed = Vector2(velocity.x, velocity.z).length()
				if h_speed > 0:
					var new_speed = max(h_speed - wall_jump_decel * delta, 0.0)
					velocity.x = velocity.x / h_speed * new_speed
					velocity.z = velocity.z / h_speed * new_speed
		
	move_and_slide()

func _process(delta: float) -> void:
	#print(Vector2(velocity.x, velocity.z).length())
	pass
	
#region ACCELERATION

func player_movement(direction: Vector3, delta):
	var current_speed = velocity.dot(direction)
	var add_speed = MAX_SPEED - current_speed
	
	if add_speed <= 0:
		return
	
	var accel_speed = GROUND_ACCEL * delta * MAX_SPEED
	
	velocity += accel_speed * direction


func air_movement(direction: Vector3, delta):
	var wish_vel = direction * MAX_SPEED
	var wish_dir = wish_vel.normalized()
	var wish_spd = min(wish_vel.length(), AIR_WISH_SPEED_CAP)
	#var wish_spd = MAX_SPEED
	
	var current_speed = velocity.dot(wish_dir)
	var add_speed = wish_spd - current_speed
	
	if add_speed <= 0: return
	
	var accel_speed = AIR_ACCEL * wish_spd * delta
	accel_speed = min(accel_speed, add_speed)
	
	velocity += accel_speed * wish_dir
	air_control(direction, delta)

func air_control(direction: Vector3, delta):
	if direction == Vector3.ZERO:
		return
	
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	if horizontal_speed == 0:
		return
	
	var wish_dir = direction.normalized()
	
	# only apply control if moving forward or backward not strafing
	# dot product close to 1 or -1 means mostly forward/back input
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

func start_slide():
	slide_timer = 0
	is_sliding = true
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
		is_sliding = false

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
	
func wallrun_check(delta, direction):
	if velocity.length() > .1:
		velocity_dir_ray.target_position = velocity.normalized() * 1.5
		
	var on_wall_rh  = is_wall(right_ray)
	var on_wall_lh  = is_wall(left_ray)
	var on_wall_vel = is_wall(velocity_dir_ray)
		
	if not is_on_floor() and (on_wall_rh or on_wall_lh or on_wall_vel):
		if not is_wallrunning:
			print(on_wall_lh, on_wall_rh, on_wall_vel)
			is_wallrunning = true
			if on_wall_vel:
				wall_normal = velocity_dir_ray.get_collision_normal()
				wallrun_side = "vel"
			elif on_wall_lh:
				wall_normal = left_ray.get_collision_normal()
				wallrun_side = "left"
			else:
				wall_normal = right_ray.get_collision_normal()
				wallrun_side = "right"
				
		# project velocity along wall
		var along_wall = wall_normal.cross(Vector3.UP).normalized()
		var horizontal_vel = Vector3(velocity.x, 0, velocity.z)
		if along_wall.dot(horizontal_vel) < 0:
			along_wall = -along_wall
		var projected = along_wall * horizontal_vel.dot(along_wall)
				
		velocity.x = projected.x
		velocity.z = projected.z
		velocity.y += Vector3.DOWN.y * WALLRUN_GRAVITY * delta
		
		var active_ray = left_ray if on_wall_lh else right_ray
		if active_ray.is_colliding():
			var hit_point = active_ray.get_collision_point()
			var target_pos = Vector3(hit_point.x, global_position.y, hit_point.z) + wall_normal * 0.5
			global_position = global_position.lerp(target_pos, 10.0 * delta)
		
		if Input.is_action_just_pressed("jump"):
			velocity = wall_normal * WALL_JUMP_HORIZONTAL
			velocity.y = WALL_JUMP_VERTICAL
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
		kick_leg.position.z = 0.0
	is_kicking = true
	kick_tween = create_tween()
	kick_tween.tween_property(kick_leg, "position:z", KICK_EXTENDED_POSITION, 0.1)
	kick_tween.tween_interval(0.2)
	kick_tween.tween_property(kick_leg, "position:z", KICK_RETRACTED_POSITION, 0.3)
	kick_tween.tween_callback(func(): is_kicking = false)

func kick_impulse():
	
	kick_cast.get_collision_normal(0)
	pass	
#endregion

#region LATCH



#endregion
