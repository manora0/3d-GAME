extends CharacterBody3D

#Player model
@onready var player_main_model : Node3D = $Player
@onready var mesh : Node3D = $Player/AnimMan

#AnimationTree
@onready var animation_player = $AnimationPlayer
@onready var animation_tree = $AnimationTree
@onready var animation_state = animation_tree.get("parameters/playback")

#camera parameter
@onready var camera_parent = get_parent().get_node("Camera")
@onready var camera_target = get_parent().get_node("Camera").get_node("CameraTarget")
var camera_T  = float()
var camera_offset : Vector3 = Vector3(0,1,0)

#input value
var input_dir = Vector2()
var input_speed = float()
var inputdir = Vector3()
var horizontal = float()
var vertical = float()

#player parameter
var gravity : float = 9.8
var jump_force : float = 6
var move_speed = float()
var walk_speed : float = 2.0
var run_speed : float = 6.0
var can_run = bool(true)
var turn_speed : float = 15
var strafe = bool(false)

#physic value
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

#animationtree transition condition
var canmove : bool
var anim_isgrounded = bool(true)
var anim_landing_idle = bool()
var start_landing_idle = bool()

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

#raycast
@onready var raycast_vault_forward = $VaultRayForwardOffset/VaultRayForward
@onready var raycast_vault_downward = $VaultRayDownward
@onready var raycast_vault_downward2 = $VaultRayDownward2
@onready var raycast_ground_distance_check = $RayGroundDistance
@onready var raycast_on_ground = $RayOnGroundCheck
@onready var raycast_forward_facing = $VaultingForwardFacing
@onready var wallrun_ray_rh = $WallRun/WallrunRay_rh
@onready var wallrun_ray_lh = $WallRun/WallrunRay_lh
@onready var wallrun_ray_center = $WallRun/WallrunRay_center

#raycast offset
@onready var raycast_vault_forward_offset = $VaultRayForwardOffset

#parkour random array
var vault_type = String()
var mantle_type = String()
var vaulting_randomize = ["vault01", "vault02", "vault03", "vault04"]
var vaulting_randomize_walk = ["vault01", "vault02", "vault03"]
var mantle_randomize = ["mantle01", "mantle02", "mantle03"]
var mantle_randomize_walk = ["mantle01", "mantle02", "mantle03"]

#wallrun
var wall_normal : Vector3
var is_wallrunning : bool = false
var wallrun_timer : float = 0.0
var wallrun_side : String = ""
const WALLRUN_MAX_TIME = 2.0
const WALLRUN_GRAVITY = 5.0

#gui
var show_label = bool(false)

#timer
@onready var jump_delay_timer = $Timer

var jump_button_pressed = false
var jump_delay = 0.05

var currentspeed = Vector2.ZERO
var anim_acceleration = 8
var inputdir_speed = 1.0

#turn in place
var angle_diff = float()
var cam_angle_diff = float()
var strafe_angle = float()
var new_diff_angle = 0.0
var new_diff_angle_acceleration = 0.1
var direction_wallrun = Vector3()


func _input(event):
	if Input.is_action_just_pressed("exit") and event.is_pressed():
		get_tree().quit()
	
	if Input.is_action_just_pressed("jump") and !(climb or vault or mantle):
		jump_button_pressed = true
		jump_delay_timer.start(jump_delay)
		raycast_vault_forward.enabled = true
		raycast_vault_forward_offset.transform = transform
		mantle_type = randomize_mantle()
		vault_type = randomize_vault()

	if Input.is_action_just_pressed("sprint") and !(climb or vault or mantle or stop_move):
		can_run = !can_run

	if Input.is_action_just_pressed("strafe"):
		strafe = !strafe


func _ready():
	Engine.max_fps = 60
	$MeshInstance3D.visible = false
	raycast_vault_forward.enabled = false
	raycast_vault_downward.global_position = self.global_position + Vector3(0, 20, 0)
	randomize()


func _process(delta):
	horizontal = Input.get_axis("left", "right")
	vertical = Input.get_axis("forward", "backward")

	player_main_model.global_transform.origin = player_main_model.global_transform.origin.lerp(self.global_transform.origin, 20 * delta)

	tpp_movement_mode(delta)
	walk_run_selection()
	anim_state()
	animation_parameter()
	root_motion(delta)
	set_camera_follow(delta)
	gui_label(delta)


func _physics_process(delta):
	get_input(delta)
	falling_velocity()
	lean_toward_acceleration(delta)
	input_strength(delta)
	player_distance_from_vault_point()
	vault_point_height()
	player_landing()
	player_stop_move()
	player_jump(delta)
	vaulting_raycast_value(delta)
	vauting_selection(delta)
	onground_check()
	angle_rotation(delta)
	wallrun_check(delta)


#region WALLRUN
func is_wall(cast: RayCast3D) -> bool:
	if not cast.is_colliding():
		return false
	return abs(cast.get_collision_normal().dot(Vector3.UP)) < 0.3

func wallrun_check(delta):
	var on_wall_rh = is_wall(wallrun_ray_rh)
	var on_wall_lh = is_wall(wallrun_ray_lh)
	
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	
	if not is_on_floor() and (on_wall_rh or on_wall_lh) and horizontal_speed > move_speed * 0.5:
		if not is_wallrunning:
			animation_state.travel("wallrun")
			is_wallrunning = true
			wallrun_timer = WALLRUN_MAX_TIME
			
			if on_wall_lh:
				wall_normal = wallrun_ray_lh.get_collision_normal()
				wallrun_side = "left"
				animation_tree.set("parameters/wallrun/Transition/transition_request", "wallrun_lh")
			else:
				wall_normal = wallrun_ray_rh.get_collision_normal()
				wallrun_side = "right"
				animation_tree.set("parameters/wallrun/Transition/transition_request", "wallrun_rh")
		
		# update wall normal each frame for curved walls
		if on_wall_lh:
			wall_normal = wallrun_ray_lh.get_collision_normal()
		elif on_wall_rh:
			wall_normal = wallrun_ray_rh.get_collision_normal()
		
		wallrun_timer -= delta
		
		# project velocity along wall
		var along_wall = wall_normal.cross(Vector3.UP).normalized()
		var horizontal_vel = Vector3(velocity.x, 0, velocity.z)
		if along_wall.dot(horizontal_vel) < 0:
			along_wall = -along_wall
		var projected = along_wall * horizontal_vel.dot(along_wall)
		
		# apply reduced gravity
		vertical_velocity += Vector3.DOWN * WALLRUN_GRAVITY * delta
		vertical_velocity.y = clamp(vertical_velocity.y, -15, 15)
		
		# apply full velocity including Y so reduced gravity takes effect
		velocity.x = projected.x
		velocity.z = projected.z
		velocity.y = vertical_velocity.y
		
		# rotate player to face along wall
		var wall_angle = atan2(along_wall.x, along_wall.z)
		rotation.y = lerp_angle(rotation.y, wall_angle, turn_speed * delta)
		
		# wall jump
		if Input.is_action_just_pressed("jump"):
			animation_state.travel("wallrun_jump")
			var jump_dir = wall_normal
			if inputdir != Vector3.ZERO:
				jump_dir = wall_normal.lerp(direction_wallrun, 0.3).normalized()
			vertical_velocity = Vector3.UP * jump_force
			velocity.x = jump_dir.x * move_speed
			velocity.z = jump_dir.z * move_speed
			velocity.y = vertical_velocity.y
			is_wallrunning = false
			
			if wallrun_side == "left":
				wallrun_ray_lh.enabled = false
				get_tree().create_timer(1.0).timeout.connect(func(): wallrun_ray_lh.enabled = true)
				animation_tree.set("parameters/wallrun_jump/Transition/transition_request", "walljump_lh")
			else:
				wallrun_ray_rh.enabled = false
				get_tree().create_timer(1.0).timeout.connect(func(): wallrun_ray_rh.enabled = true)
				animation_tree.set("parameters/wallrun_jump/Transition/transition_request", "walljump_rh")
			return
		
		# exit conditions
		if wallrun_timer <= 0 or is_on_floor():
			is_wallrunning = false
			animation_state.travel("JUMP")
	else:
		if is_wallrunning:
			is_wallrunning = false
			animation_state.travel("JUMP")

#endregion


#region ANIMATION STATE
func anim_state():
	var current_animation_state = animation_state.get_current_node()
	climb = "CLIMB" in current_animation_state
	vault = "VAULT" in current_animation_state
	mantle = "MANTLE" in current_animation_state
	landing = "LANDING" in current_animation_state
	stop_move = "STOP MOVE" in current_animation_state
	landing_end = "LANDING END" in current_animation_state
	jump = "JUMP" in current_animation_state
	idle = "IDLE" in current_animation_state
	move = "MOVE" in current_animation_state

func animation_parameter():
	animation_tree.set("parameters/conditions/idle", !canmove)
	animation_tree.set("parameters/conditions/startmove", canmove)
	animation_tree.set("parameters/conditions/isgrounded", anim_isgrounded)
	animation_tree.set("parameters/conditions/isnotgrounded", !anim_isgrounded)
	animation_tree.set("parameters/conditions/landing_idle", anim_landing_idle)
	animation_tree.set("parameters/conditions/landing_move", !anim_landing_idle)
	animation_tree.set("parameters/conditions/isgrounded_idle", start_landing_idle)
	animation_tree.set("parameters/conditions/isgrounded_move", !start_landing_idle)

#endregion


#region ROOT MOTION
func root_motion(delta):
	var root_pos = animation_tree.get_root_motion_position()
	var current_rotation = (animation_tree.get_root_motion_rotation_accumulator().inverse() * get_quaternion())
	root_velocity = current_rotation * root_pos / delta
	var root_rotation = animation_tree.get_root_motion_rotation()
	set_quaternion(get_quaternion() * root_rotation)
	enable_root_motion = climb or vault or mantle or landing

#endregion


#region CAMERA FOLLOW
func set_camera_follow(delta):
	var cam_timer = clamp(delta * 300 / 20, 0, 1)
	camera_parent.global_transform.origin = camera_parent.global_transform.origin.lerp(self.global_transform.origin + camera_offset, cam_timer)

#endregion


#region PLAYER INPUT
func get_input(delta):
	camera_T = camera_target.global_transform.basis.get_euler().y
	inputdir = Vector3(horizontal, 0, vertical).normalized()

	if inputdir != Vector3.ZERO:
		direction = Vector3(-inputdir.x, 0, -inputdir.z).rotated(Vector3.UP, camera_T).normalized()
	else:
		direction = Vector3.ZERO

	if direction != Vector3.ZERO:
		if anim_isgrounded:
			player_velocity = player_velocity.lerp(direction * move_speed, 8 * delta)
			canmove = true
		else:
			player_velocity = player_velocity.lerp(direction * move_speed, 8 * delta)
	else:
		if anim_isgrounded:
			player_velocity = player_velocity.lerp(Vector3.ZERO, 15 * delta)
			canmove = false
		else:
			player_velocity = player_velocity.lerp(direction * move_speed, delta)

	var root_motion_no_y = Vector3(root_velocity.x, 0, root_velocity.z)
	if enable_root_motion:
		if disable_root_motion_y:
			velocity = root_motion_no_y
		else:
			if !landing:
				velocity = root_velocity
			else:
				velocity = root_velocity + vertical_velocity
	else:
		if not is_wallrunning:
			velocity = player_velocity + vertical_velocity

	if strafe:
		run_speed = 6.0
		if direction != Vector3.ZERO:
			if !(climb or vault or mantle):
				rotation.y = lerp_angle(rotation.y, camera_T, delta * turn_speed)
				mesh.rotation.y = lerp_angle(mesh.rotation.y, rotation.y, delta * turn_speed)
	else:
		run_speed = 6.0
		if direction != Vector3.ZERO:
			if !(climb or vault or mantle) and not is_wallrunning:
				rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), turn_speed * delta)
				rotation_transform = mesh.transform.looking_at(-player_velocity, Vector3.UP)
				mesh.transform = mesh.transform.interpolate_with(rotation_transform, turn_speed * delta)
		
		# update wallrun direction relative to player rotation
		var rot = global_transform.basis.get_euler().y
		direction_wallrun = Vector3(horizontal, 0, vertical).rotated(Vector3.UP, rot).normalized()
		

	move_and_slide()

#endregion


#region TPP MODE
func tpp_movement_mode(delta):
	if strafe:
		strafing_movement(delta)
		animation_tree.set("parameters/MOVE/tpp mode/transition_request", "strafe")
	else:
		animation_tree.set("parameters/MOVE/tpp mode/transition_request", "nonstrafe")

func strafing_movement(delta):
	var targetspeed = Vector2(inputdir.x, inputdir.z) * inputdir_speed
	currentspeed = currentspeed.move_toward(targetspeed, anim_acceleration * delta)
	var strafe_input = Vector2(currentspeed.x, -currentspeed.y)
	animation_tree.set("parameters/MOVE/strafe movement/blend_position", strafe_input)

#endregion


#region RUN WALK MODE
func walk_run_selection():
	if can_run:
		anim_acceleration = 8
		inputdir_speed = 1.0
		move_speed = run_speed
		animation_tree.set("parameters/MOVE/Movement/transition_request", "run")
		animation_tree.set("parameters/STOP MOVE/walk_run/transition_request", "run")
	else:
		anim_acceleration = 2
		inputdir_speed = 0.4
		animation_tree.set("parameters/MOVE/Movement/transition_request", "walk")
		animation_tree.set("parameters/STOP MOVE/walk_run/transition_request", "walk")
		move_speed = walk_speed

	var running = animation_tree.get("parameters/MOVE/Movement/current_state") == "run"
	var walking = animation_tree.get("parameters/MOVE/Movement/current_state") == "walk"
	
	if !can_run and running:
		animation_tree.set("parameters/MOVE/TimeSeek/seek_request", 0.87)
		animation_tree.set("parameters/MOVE/Run_to_Walk_oneshot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

	if can_run and walking:
		animation_tree.set("parameters/MOVE/TimeSeek 2/seek_request", 1.23)
		animation_tree.set("parameters/MOVE/Walk_to_run_oneshot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

#endregion


func input_strength(delta):
	direction_velocity = direction_velocity.lerp(Vector3(velocity.x, 0, velocity.z), 50 * delta)
	return direction_velocity.length()


#region PLAYER LEANING
func lean_toward_acceleration(delta):
	if anim_isgrounded:
		if direction != Vector3.ZERO:
			lean_velocity = lean_velocity.lerp(direction * move_speed, 3 * delta)
		else:
			lean_velocity = lean_velocity.lerp(Vector3.ZERO, 3 * delta)

	lean_acceleration = lean_velocity - last_lean_velocity
	lean = lean_acceleration.cross(Vector3.UP) * 1.1
	player_main_model.rotation = lerp(player_main_model.rotation, -lean, 4 * delta)
	last_lean_velocity = lean_velocity

#endregion


#region PLAYER JUMP
func player_jump(delta):
	jump_block = raycast_vault_forward.is_colliding() and raycast_vault_downward.is_colliding()

	if !is_on_floor():
		if not is_wallrunning:
			vertical_velocity += Vector3.DOWN * gravity * 1.5 * delta
	else:
		vertical_velocity.y = -0.1

	if vertical_velocity.y < 0 and !is_on_floor():
		vertical_velocity.y = clamp(vertical_velocity.y, -20, 15)

	if !(landing):
		last_input_strength = input_strength(delta)

func normal_jump():
	if !jump_block:
		if is_on_floor():
			vertical_velocity = Vector3.UP * jump_force
		if landing or stop_move or landing_end:
			animation_state.travel("JUMP")
	jump_button_pressed = false

#endregion


#region STOP MOVE STEP
func player_stop_move():
	var last_foot_step = $foot_lh.position.y
	if !stop_move:
		if last_foot_step >= 0.8:
			animation_tree.set("parameters/STOP MOVE/Stop_move_side/transition_request", "stop_move_rh")
			animation_tree.set("parameters/STOP MOVE/Stop_move_side WALK/transition_request", "stop_move_rh")
		else:
			animation_tree.set("parameters/STOP MOVE/Stop_move_side/transition_request", "stop_move_lh")
			animation_tree.set("parameters/STOP MOVE/Stop_move_side WALK/transition_request", "stop_move_lh")

	if strafe:
		animation_tree.set("parameters/STOP MOVE/Stop Move Mode/transition_request", "strafe")
	else:
		animation_tree.set("parameters/STOP MOVE/Stop Move Mode/transition_request", "nonstrafe")

	if !stop_move or !move:
		if new_diff_angle > 70 and new_diff_angle < 100:
			animation_tree.set("parameters/STOP MOVE/Strafe Stop Move/strafe stop move/transition_request", "RIGHT")
		elif new_diff_angle < -70 and new_diff_angle > -100:
			animation_tree.set("parameters/STOP MOVE/Strafe Stop Move/strafe stop move/transition_request", "LEFT")
		elif angle_diff > -20 and angle_diff < 20:
			animation_tree.set("parameters/STOP MOVE/Strafe Stop Move/strafe stop move/transition_request", "FORWARD")

#endregion


#region PLAYER LANDING
func falling_velocity():
	var dst_from_ground = float()
	if jump:
		dst_from_ground = self.global_transform.origin.distance_to(raycast_ground_distance_check.get_collision_point())
		if raycast_ground_distance_check.is_colliding():
			if dst_from_ground >= 0.07:
				last_falling_velocity = vertical_velocity.y

func player_landing():
	if landing and direction == Vector3.ZERO:
		anim_landing_idle = true
	else:
		anim_landing_idle = false

	if landing_end or landing:
		if direction != Vector3.ZERO:
			animation_state.travel("MOVE")

	if last_input_strength <= 5:
		animation_tree.set("parameters/LANDING/Land Velocity/transition_request", "land_stand")
		animation_tree.set("parameters/LANDING END/Transition/transition_request", "stop_idle")
	else:
		animation_tree.set("parameters/LANDING/Land Velocity/transition_request", "land_move")
		animation_tree.set("parameters/LANDING END/Transition/transition_request", "stop_move")

	animation_tree.set("parameters/LANDING/jump blend_stand/blend_position", last_falling_velocity)
	animation_tree.set("parameters/LANDING/jump blend_move/blend_position", last_falling_velocity)

#endregion


#region PARKOUR
func vaulting_raycast_value(_delta):
	if raycast_vault_downward.is_colliding():
		normal_direction = -raycast_forward_facing.get_collision_normal()
	else:
		normal_direction = Vector3.ZERO

	if climb or vault or mantle:
		pass
	else:
		Engine.time_scale = 1.0

	if raycast_vault_forward.is_colliding():
		raycast_vault_downward.global_transform.origin = raycast_vault_forward.get_collision_point(0) + Vector3(0, 5, 0.1).rotated(Vector3.UP, global_transform.basis.get_euler().y)
		raycast_vault_downward2.global_transform.origin = raycast_vault_forward.get_collision_point(0) + Vector3(0, 5, 1).rotated(Vector3.UP, global_transform.basis.get_euler().y)
	else:
		raycast_vault_downward.global_transform.origin = Vector3.ZERO
		raycast_vault_downward2.global_transform.origin = Vector3.ZERO

func vauting_selection(delta):
	if raycast_vault_downward2.is_colliding():
		animation_tree.set("parameters/VAULT/vault_mantle/transition_request", "mantle_1m")
	else:
		animation_tree.set("parameters/VAULT/vault_mantle/transition_request", "vault_1m")

	if raycast_vault_forward.is_colliding() and raycast_vault_downward.is_colliding():
		if vault_point_height() > 0.2 and vault_point_height() <= 1.6:
			if raycast_vault_downward2.is_colliding():
				mantle_1m(delta)
			else:
				if vault_point_height() >= 0.9:
					vaulting_1m(delta)
				elif vault_point_height() < 0.9:
					vault_step_jump()
		elif vault_point_height() > 1.6:
			climb_2_5m(delta)

func player_distance_from_vault_point():
	var dst_from_vault_point = float()
	if raycast_vault_forward.is_colliding():
		dst_from_vault_point = self.global_transform.origin.distance_to(raycast_vault_forward.get_collision_point(0)) - 1.7
	return dst_from_vault_point

func randomize_vault():
	var random_vault = vaulting_randomize[randi() % vaulting_randomize.size()]
	var random_vault_walk = vaulting_randomize_walk[randi() % vaulting_randomize_walk.size()]
	if can_run: return random_vault
	if !can_run: return random_vault_walk

func randomize_mantle():
	var random_mantle = mantle_randomize[randi() % mantle_randomize.size()]
	var random_mantle_walk = mantle_randomize_walk[randi() % mantle_randomize_walk.size()]
	if can_run: return random_mantle
	if !can_run: return random_mantle_walk

func align_to_wall(delta):
	rotation.y = atan2(normal_direction.x, normal_direction.z)
	rotation_transform = mesh.transform.looking_at(-normal_direction, Vector3.UP)
	mesh.transform = mesh.transform.interpolate_with(rotation_transform, turn_speed * delta)

func vault_point_height():
	var vault_height = float()
	if raycast_vault_downward.is_colliding():
		vault_height = raycast_vault_downward.get_collision_point(0).y - raycast_ground_distance_check.get_collision_point().y
	else:
		vault_height = 0
	return vault_height

func start_vault():
	disable_root_motion_y = true
	animation_tree.set("parameters/CLIMB/Add2/add_amount", 0.64)

func end_vault():
	$CollisionShape3D.disabled = false
	disable_root_motion_y = false
	raycast_vault_forward.enabled = false

func enable_collision():
	$CollisionShape3D.disabled = false

func end_fix_hand():
	animation_tree.set("parameters/CLIMB/Add2/add_amount", 0.0)

func vault_step_jump():
	animation_state.travel("RUN VAULT")

func vaulting_1m(delta):
	animation_tree.set("parameters/VAULT/vault_type/transition_request", vault_type)
	var vault_1m_vault_point = Vector3()
	var vault_point_offset = Vector3(0, 0, 0).rotated(Vector3.UP, global_transform.basis.get_euler().y)
	vault_1m_vault_point = raycast_vault_downward.get_collision_point(0) + vault_point_offset
	$MeshInstance3D.global_transform.origin = vault_1m_vault_point
	animation_state.travel("VAULT")
	
	var vault_speed = delta * 10
	var vault_point_dst = float()
	if disable_root_motion_y:
		vertical_velocity.y = 0
		align_to_wall(delta)
		$CollisionShape3D.disabled = true
		vault_point_dst = self.global_transform.origin.distance_to(vault_1m_vault_point)
		var timer = clamp(vault_speed / vault_point_dst, 0, 1)
		self.global_transform.origin = lerp(self.global_transform.origin, vault_1m_vault_point, timer)
		var vaulting_timescale = clamp(1.2 - vault_point_dst, 0.5, 1)
		animation_tree.set("parameters/VAULT/VaultSpeed/scale", vaulting_timescale)
	else:
		animation_tree.set("parameters/VAULT/VaultSpeed/scale", 1)
		$CollisionShape3D.disabled = false

func mantle_1m(delta):
	animation_tree.set("parameters/MANTLE/mantle_type/transition_request", mantle_type)
	var mantle_1m_vault_point = Vector3()
	var mantle_point_offset = Vector3(0, 0, 0).rotated(Vector3.UP, global_transform.basis.get_euler().y)
	mantle_1m_vault_point = raycast_vault_downward.get_collision_point(0) + mantle_point_offset
	$MeshInstance3D.global_transform.origin = mantle_1m_vault_point
	animation_state.travel("MANTLE")
	
	var mantle_speed = delta * 10
	var mantle_point_dst = float()
	if disable_root_motion_y:
		vertical_velocity.y = 0
		$CollisionShape3D.disabled = true
		mantle_point_dst = self.global_transform.origin.distance_to(mantle_1m_vault_point)
		var timer = clamp(mantle_speed / mantle_point_dst, 0, 1)
		self.global_transform.origin = lerp(self.global_transform.origin, mantle_1m_vault_point, timer)
		var mantle_timescale = clamp(1.2 - mantle_point_dst, 0.4, 1)
		animation_tree.set("parameters/MANTLE/MantleSpeed/scale", mantle_timescale)
	else:
		$CollisionShape3D.disabled = false
		animation_tree.set("parameters/MANTLE/MantleSpeed/scale", 1)

func climb_2_5m(delta):
	var climb_2_5m_point = global_position
	var climb_2_5m_point_offset = Vector3(0, -1.5, -0.55).rotated(Vector3.UP, global_transform.basis.get_euler().y)
	if normal_direction == Vector3.ZERO:
		return
	climb_2_5m_point = raycast_vault_downward.get_collision_point(0) + climb_2_5m_point_offset
	$MeshInstance3D.global_transform.origin = climb_2_5m_point
	animation_state.travel("CLIMB")
	var climb_speed = delta * 20
	if vault_point_height() < 2.5:
		climb_speed = delta * 20
	else:
		climb_speed = delta * 10
	var climb_point_dst = float()
	if disable_root_motion_y:
		align_to_wall(delta)
		climb_point_dst = self.global_transform.origin.distance_to(climb_2_5m_point)
		var timer = clamp(climb_speed / climb_point_dst, 0, 1)
		self.global_transform.origin = lerp(self.global_transform.origin, climb_2_5m_point, timer)
		var climb_timescale = clamp(1.2 - climb_point_dst, 0.6, 1)
		animation_tree.set("parameters/CLIMB/ClimbSpeed/scale", climb_timescale)
	else:
		animation_tree.set("parameters/MANTLE/MantleSpeed/scale", 1)

#endregion


#region CHECK GROUND
func onground_check():
	if raycast_on_ground.is_colliding():
		anim_isgrounded = true
	else:
		anim_isgrounded = false

#endregion

func angle_rotation(delta):
	var target_direction = (Vector3.FORWARD * inputdir.z + Vector3.RIGHT * inputdir.x).rotated(Vector3.UP, camera_T)
	var cam_direction = Vector3.BACK.rotated(Vector3.UP, camera_T)
	var forward_direction = global_transform.basis.z.normalized()
	angle_diff = rad_to_deg(forward_direction.signed_angle_to(target_direction, Vector3.UP))
	cam_angle_diff = rad_to_deg(forward_direction.signed_angle_to(cam_direction, Vector3.UP))
	if direction != Vector3.ZERO:
		new_diff_angle = angle_diff
	else:
		new_diff_angle = move_toward(new_diff_angle, angle_diff, new_diff_angle_acceleration * delta)


#region GUI
func gui_label(delta):
	if Input.is_action_just_pressed("tab"):
		show_label = !show_label
	if show_label:
		var label_line01 = "Input Velocity : " + str(snapped(input_strength(delta), 0.1)) + "\n Input Speed : " + str(snapped(input_speed, 0.1))
		var label_line02 = "\n Acceleration : " + str(snapped(lean_acceleration.length(), 0.1)) + "\n Velocity : " + str(snapped(velocity.length() * 10, 0.1))
		var label_line03 = "\n State : " + animation_state.get_current_node() + "\n Dst from Vault : " + str(snapped(player_distance_from_vault_point() * 10, 0.1))
		var label_line04 = "\n Falling Velocity : " + str(snapped(vertical_velocity.y, 0.1)) + "\n Last Falling Velocity : " + str(snapped(last_falling_velocity, 0.1))
		var label_line05 = "\n Wallrunning : " + str(is_wallrunning) + "\n Wall Side : " + wallrun_side
		$Indicator/InputStrength.text = label_line01 + label_line02 + label_line03 + label_line04 + label_line05
	else:
		$Indicator/InputStrength.text = ""

#endregion
