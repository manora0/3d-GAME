extends Node3D

@export var linked_wall: CollisionObject3D

func on_shot():
	if linked_wall:
		linked_wall.collision_layer = 0
		linked_wall.collision_mask = 0
		linked_wall.hide()
