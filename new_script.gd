@tool
extends EditorScript

func _run():
	var path = "res://merged_animations.res"
	var lib = load(path)
	
	if not lib is AnimationLibrary:
		print("Not an AnimationLibrary")
		return
	
	var fixed = 0
	
	for anim_name in lib.get_animation_list():
		var anim = lib.get_animation(anim_name)
		
		for track_idx in anim.get_track_count():
			var track_path = str(anim.track_get_path(track_idx))
			var track_type = anim.track_get_type(track_idx)
			
			if "Hips" in track_path and track_type == Animation.TYPE_POSITION_3D:
				for key_idx in anim.track_get_key_count(track_idx):
					var pos = anim.track_get_key_value(track_idx, key_idx)
					anim.track_set_key_value(track_idx, key_idx, Vector3(0, pos.y, 0))
				fixed += 1
				print("Fixed: ", anim_name)
	
	var err = ResourceSaver.save(lib, path)
	if err == OK:
		print("Done — fixed ", fixed, " tracks")
	else:
		print("Failed: ", err)
