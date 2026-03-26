extends State
class_name Wallrun

var entry_velocity
var colliding_ray : RayCast3D

var wall_normal : Vector3
var wall_up = Vector3.UP
var along_wall : Vector3

func Enter():
	if player.ray_left.is_colliding():
		colliding_ray = player.ray_left
		player.falling.travel("WallRun_L")
	elif player.ray_right.is_colliding():
		colliding_ray = player.ray_right
		player.falling.travel("WallRun_R")
	
	wall_normal = colliding_ray.get_collision_normal()
	along_wall = wall_normal.cross(Vector3.UP).normalized()
	
	var collision_point = colliding_ray.get_collision_point()
	var target = collision_point + wall_normal * 3.6 # player radius
	target.y = player.global_position.y
	player.global_position = target
	
	var horizontal_vel = Vector3(player.velocity.x, 0, player.velocity.z)
	if along_wall.dot(horizontal_vel) < 0:
		along_wall = -along_wall
	var projected_speed = horizontal_vel.dot(along_wall)
	var projected_velocity = along_wall * projected_speed
	
	var wall_angle = atan2(along_wall.x, along_wall.z)
	player.rotation.y = wall_angle
	
	player.velocity.x = projected_velocity.x
	player.velocity.z = projected_velocity.z
	player.velocity.y *= 1.2
	
	player.gravity_scale = 0.7
	
	player.head.lock_body(false)
	
	pass

func Exit():
	player.head.lock_body(true)
	player.gravity_scale = 1.0
	
	if not player.is_on_floor():
		if colliding_ray == player.ray_left:
			player.ray_left.enabled = false
			player.get_tree().create_timer(1.0).timeout.connect(
				func(): player.ray_left.enabled = true
			)
			player.falling.travel("WallRun_Jump_L")
		else:
			player.ray_right.enabled = false
			player.get_tree().create_timer(1.0).timeout.connect(
				func(): player.ray_right.enabled = true
			)
			player.falling.travel("WallRun_Jump_R")
	else:
		player.falling.travel("end")


func Physics_Update(_delta: float):
	if Input.is_action_just_pressed("jump"):
		var cur_input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var direction := (player.transform.basis * Vector3(cur_input.x, 0, cur_input.y)).normalized()
		
		# base jump is perpendicular to wall
		var jump_dir = wall_normal
		
		# if holding a direction, blend it in but keep wall normal dominant
		if cur_input != Vector2.ZERO:
			jump_dir = wall_normal.lerp(direction, 0.8).normalized()
		
		player.velocity.x = jump_dir.x * player.RUNSPEED
		player.velocity.z = jump_dir.z * player.RUNSPEED
		player.velocity.y = player.JUMP_VELOCITY
		
		Transitioned.emit(self, "Jump")
	pass

func Update(_delta: float):
	print(colliding_ray.is_colliding())
	if not colliding_ray.is_colliding():
		Transitioned.emit(self, "Jump")
		return
	if player.is_on_floor():
		Transitioned.emit(self, "Standing")
		return
