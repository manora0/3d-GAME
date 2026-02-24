extends State

var can_jump : bool = true
var playback_path = "parameters/Locomotion/playback"

func Enter():
	begin_jump()
	can_jump = true
	
func Exit():
	pass
	
func Update(_delta: float):
	pass
	
func Physics_Update(_delta: float):
	if Input.is_action_pressed("ui_accept") and can_jump:
		player.velocity.y = player.JUMP_VELOCITY
		can_jump = false
	
	if player.is_on_floor():
		return_idle()
		if (player.state_machine.prev_state):
			Transitioned.emit(self, player.state_machine.prev_state.name)
		else:
			Transitioned.emit(self, 'Idle')

func begin_jump():
	var playback = player.animationtree.get(playback_path) as AnimationNodeStateMachinePlayback
	playback.travel("d_Jump_Start")
	
func return_idle():
	var playback = player.animationtree.get(playback_path) as AnimationNodeStateMachinePlayback
	playback.travel("d_Jump_Land")
	
func execute_jump_velocity():
	pass
	
