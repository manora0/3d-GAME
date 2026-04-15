extends Node
class_name Sequencer




var machine : StateMachines

func _init(machine:StateMachines):
	self.machine = machine

func request_transition(from:States, to:States):
	pass

func end_transition(from:States, to:States):
	pass
	
class ISequence:
	var is_done : bool
	
	func start():
		pass
	
	func update():
		pass
	

class noophase:
	extends ISequence
	
	func start():
		is_done = true
	
	func update():
		pass
		
	
		
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
 
