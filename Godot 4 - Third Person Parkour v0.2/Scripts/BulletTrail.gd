extends MeshInstance3D

const LIFETIME := 0.12

func init(from: Vector3, to: Vector3) -> void:
	var dir = (to - from).normalized()
	var length = from.distance_to(to)

	global_position = (from + to) * 0.5

	# Build basis with Y axis aligned along the trail direction
	var ref = Vector3.FORWARD if abs(dir.dot(Vector3.UP)) > 0.99 else Vector3.UP
	var x_axis = dir.cross(ref).normalized()
	var z_axis = x_axis.cross(dir)
	global_transform.basis = Basis(x_axis, dir, z_axis)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.75, 0.1)
	mat.emission_energy_multiplier = 4.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.01
	mesh.bottom_radius = 0.01
	mesh.height = length
	mesh.rings = 1
	mesh.radial_segments = 4
	mesh.material = mat
	self.mesh = mesh

	var tween := create_tween()
	tween.tween_method(func(a: float): mat.albedo_color.a = a, 1.0, 0.0, LIFETIME)
	tween.tween_callback(queue_free)
