# Player.gd (on the Player Node3D)
extends Node3D

func start_vault():
	get_parent().start_vault()

func end_vault():
	get_parent().end_vault()

func enable_collision():
	get_parent().enable_collision()

func end_fix_hand():
	get_parent().end_fix_hand()
