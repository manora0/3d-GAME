extends Area3D

@export var collision_shape: CollisionShape3D
@export var player_group: String = "player"
@export var label_node_path: String = "Control/VelocityLabel"

var time_outside: float = 0.0
var last_time: float = 0.0
var player_inside: bool = true
var is_running: bool = false
var label: Label = null

signal timer_updated(time: float)
signal player_left_zone(time: float)
signal player_entered_zone(time: float)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if is_running:
		time_outside += delta
		emit_signal("timer_updated", time_outside)
		if label:
			label.text = "OUT: %.2fs" % time_outside

func _get_label(body: Node3D) -> void:
	if label == null:
		label = body.get_node_or_null(label_node_path)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group(player_group):
		_get_label(body)
		player_inside = false
		time_outside = 0.0
		is_running = true
		emit_signal("player_left_zone", time_outside)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(player_group):
		_get_label(body)
		player_inside = true
		is_running = false
		last_time = time_outside
		emit_signal("player_entered_zone", time_outside)
		if label:
			label.text = "IN ZONE  |  Last: %.2fs" % last_time if last_time > 0.0 else "IN ZONE"
