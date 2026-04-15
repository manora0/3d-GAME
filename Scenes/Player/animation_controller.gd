#extends Node
#class_name AnimationController
#
#@export var machine:StateMachine
#@export var anim_tree: AnimationTree
#
#@onready var locomotion : AnimationNodeStateMachinePlayback = anim_tree.get("parameters/locomotion/playback")
#@onready var crouch : AnimationNodeStateMachinePlayback = anim_tree.get("parameters/locomotion/crouch/playback")
#@onready var slide : AnimationNodeStateMachinePlayback = anim_tree.get("parameters/locomotion/slide/playback")
#@onready var sprint : AnimationNodeStateMachinePlayback = anim_tree.get("parameters/locomotion/sprint/playback")
#@onready var falling : AnimationNodeStateMachinePlayback = anim_tree.get("parameters/falling_state/playback")
#var midair_oneshot = "parameters/midair/request"
#var crouch_blend = "parameters/locomotion/crouch/crouching/blend_position"
#var walk_blend = "parameters/locomotion/walk/blend_position"
#
#var busy : bool
#var current_state : State
#
#func animation_request(to):
	#
	#pass
#
#
#
#
#class package:
	#var from : State
	#var to : State
	#
	#func _init(from:State, to:State):
		#self.from = from
		#self.to = to
	#
	
