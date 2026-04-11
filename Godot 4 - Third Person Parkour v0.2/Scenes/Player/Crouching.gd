extends State
class_name Crouching

const SLIDE_THRESHOLD = 1.5
const FRICTION = 10.0

var blend_position: Vector2 = Vector2.ZERO       # Current value being sent to the BlendSpace2D
var target_blend: Vector2 = Vector2.ZERO         # what blend position iss omving toward
var transition_speed: float = 3.0             # how fast blend position chases target blend
var was_sliding: bool = false                    # tracks if crossed slide threshold last frame
var entry_speed: float = 0.0                     # speed captured on enter, used as a remap ceiling

const SPEED_THRESHOLD = 20


"""
captures the speed at the moment of entry and if going fast enough then play slide
"""
func Enter():
	
	# captures the speed at entry
	player.locomotion.travel("Crouching")
	var horizontal = Vector2(player.velocity.x, player.velocity.z)
	entry_speed = horizontal.length()
	
	# if speed is above or at the walking speed then slide
	if entry_speed >= player.SPEED:
		was_sliding = true
		player.head.lock_body(false)
		player.crouch.travel("Slide_Start")
		call_deferred("set_slide_rotation")
	else:
		player.crouch.travel("d_Crouch_Enter")
		was_sliding = false

func set_slide_rotation():
	var horizontal = Vector2(player.velocity.x, player.velocity.z)
	var horizontal_dir = horizontal.normalized()
	var world_angle = atan2(horizontal_dir.x, horizontal_dir.y)
	var local_angle = world_angle - player.global_rotation.y
	player.mesh.rotation.y = local_angle

func Exit():
	if was_sliding:
		player.crouch.travel("Slide_Exit")
		player.head.lock_body(true)
		player.mesh.rotation = Vector3.ZERO
	else:
		player.crouch.travel("d_Crawl_Exit")

func Physics_Update(_delta:float):
	# get input
	var input_dir = Input.get_vector("move_right", "move_left" , "move_back", "move_forward")
	var direction := (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# map current velocity to blendspace2d
	var current_speed = Vector2(player.velocity.x, player.velocity.z).length()
	var speed_map = clamp(remap(current_speed, 0.0, player.SPEED * 2, 0.0, 2.0), 0.0, 2.0)

	if was_sliding: # if sliding, apply friction
		var target_speed = move_toward(current_speed, player.CROUCH_SPEED, FRICTION * _delta)
		var horizontal_dir = Vector2(player.velocity.x, player.velocity.z).normalized()

		player.velocity.x = horizontal_dir.x * target_speed
		player.velocity.z = horizontal_dir.y * target_speed
		
		target_blend = Vector2(
			2.0 if abs(horizontal_dir.x) > abs(horizontal_dir.y) else 0.0,
			0.0 if abs(horizontal_dir.x) > abs(horizontal_dir.y) else 2.0
		) * Vector2(sign(horizontal_dir.x), sign(horizontal_dir.y))
		
		if player.velocity.length() <= 20:
			var current_dir = target_blend.normalized()
			target_blend = current_dir * 1.0
			was_sliding = false
			player.head.lock_body(true)
			player.mesh.rotation = Vector3.ZERO
			
	else:
		if direction != Vector3.ZERO:
			player.velocity.x = direction.x * player.CROUCH_SPEED
			player.velocity.z = direction.z * player.CROUCH_SPEED
		else:
			player.velocity.x = move_toward(player.velocity.x, 0.0, player.RUNSPEED * 2 * _delta)
			player.velocity.z = move_toward(player.velocity.z, 0.0, player.RUNSPEED * 2 * _delta)
		
		target_blend.x = move_toward(target_blend.x, input_dir.x * speed_map, transition_speed * _delta)
		target_blend.y = move_toward(target_blend.y, input_dir.y * speed_map, transition_speed * _delta)


func Update(_delta: float):
	var current_speed = Vector2(player.velocity.x, player.velocity.z).length()
	
	# how close to the speed threshold, 0 = at threshold, 1 = far from it
	var threshold_distance = clamp((current_speed - player.CROUCH_SPEED) / (entry_speed - player.CROUCH_SPEED), 0.0, 1.0)
	
	if was_sliding:
		# smooth blend following velocity
		blend_position.x = move_toward(blend_position.x, target_blend.x, transition_speed * _delta)
		blend_position.y = move_toward(blend_position.y, target_blend.y, transition_speed * _delta)
	else:
		# ease from smooth to snap based on how far from threshold we are
		var effective_speed = lerp(transition_speed, transition_speed * 100.0, threshold_distance)
		blend_position.x = move_toward(blend_position.x, target_blend.x, effective_speed * _delta)
		blend_position.y = move_toward(blend_position.y, target_blend.y, effective_speed * _delta)

	player.animationtree[player.crouch_blend] = blend_position

	check_transitions()

func check_transitions():
	if Input.is_action_just_pressed("jump"):
		Transitioned.emit(self, "Jump")
		return
	if not Input.is_action_pressed("slide"):
		Transitioned.emit(self, "Standing")
		return
