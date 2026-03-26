extends State
class_name Vault

var can_transition: bool = false
var timer: Timer

func Enter():
	can_transition = false
	player.gravity_scale = 0.0
	player.locomotion.travel("SafetyVault_RM")
	
	if not timer:
		timer = Timer.new()
		add_child(timer)
		timer.one_shot = true
		timer.timeout.connect(func(): can_transition = true)
	timer.start(0.5)
	
	player.standing_shape.disabled = true

func Exit():
	player.gravity_scale = 1.0
	player.velocity = Vector3.ZERO
	
	player.standing_shape.disabled = false


func Physics_Update(_delta: float):
	var root_motion = player.animationtree.get_root_motion_position()
	var motion = player.global_transform.basis * root_motion
	player.velocity = motion * 2 / _delta
	
	print("root_motion this frame: ", root_motion)
	print("magnitude: ", root_motion.length())

func Update(_delta: float):
	if not can_transition:
		return
	
	var playback = player.animationtree["parameters/locomotion/playback"]
	if playback.get_current_node() != "SafetyVault_RM":
		if Input.is_action_pressed("slide"):
			Transitioned.emit(self, "Crouching")
		else:
			Transitioned.emit(self, "Standing")
