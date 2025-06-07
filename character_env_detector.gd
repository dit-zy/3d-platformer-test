extends Area3D


@export_range(0, 64) var num_rays: int
@export_range(0, 10) var detection_distance: float
@export_range(0, 180, 1, "radians_as_degrees") var max_ray_misalignment_angle: float
@export_color_no_alpha var valid_norm_color: Color
@export_color_no_alpha var invalid_norm_color: Color


var rays: Array[RayCast3D] = []
var debug_enabled = false
var max_ray_misalignment: float


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	max_ray_misalignment = cos(max_ray_misalignment_angle)
	#print("max ray misalignment : {}".format([max_ray_misalignment], "{}"))
	
	var mat = ($debugnorm as MeshInstance3D).mesh.surface_get_material(0)
	for i in range(num_rays):
		var ray = RayCast3D.new()
		ray.target_position = detection_distance*Vector3(cos(i*TAU/num_rays), 0, sin(i*TAU/num_rays))
		ray.collision_mask = 2
		ray.enabled = false
		var cube = $debugcube.duplicate() as Node3D
		var norm = $debugnorm.duplicate() as MeshInstance3D
		norm.set_surface_override_material(0, mat.duplicate())
		ray.add_child(cube)
		ray.add_child(norm)
		cube.position = ray.target_position * (detection_distance-.5)
		cube.quaternion = Quaternion(Vector3.UP, ray.target_position)
		add_child(ray)
		rays.append(ray)
	
	set_debug_enabled(debug_enabled)


func set_debug_enabled(enabled: bool) -> void:
	debug_enabled = enabled
	for ray in rays:
		for debug_obj in ray.get_children():
			(debug_obj as Node3D).visible = enabled


func toggle_debug_enabled() -> void:
	set_debug_enabled(not debug_enabled)


func find_wall_dir() -> Vector3:
	var wall_dir = Vector3.ZERO
	var num_walls = 0
	for ray in rays:
		ray.force_raycast_update()
		var debugnorm = ray.get_child(1) as MeshInstance3D
		
		if not ray.is_colliding():
			debugnorm.position = Vector3.UP*4
			debugnorm.quaternion = Quaternion.IDENTITY
			continue
		
		var norm_mat = debugnorm.get_surface_override_material(0) as StandardMaterial3D
		var norm = ray.get_collision_normal().normalized()
		
		debugnorm.position = (ray.get_collision_point() + norm/4)*ray.global_transform
		debugnorm.quaternion = Quaternion(Vector3.UP, norm*ray.global_transform.basis)
		
		var target_dir = (ray.global_transform*ray.target_position - ray.global_position).normalized()
		var ray_alignment = target_dir.dot(-norm)
		if false and debug_enabled and .98 < ray.target_position.normalized().dot(Vector3.FORWARD):
			print("t_dir : {} | norm : {} | align : {}".format([target_dir, norm, ray_alignment], "{}"))
		
		if ray_alignment < max_ray_misalignment:
			norm_mat.albedo_color = invalid_norm_color
			norm_mat.emission = invalid_norm_color
			continue
		
		norm_mat.albedo_color = valid_norm_color
		norm_mat.emission = valid_norm_color
		wall_dir += -norm
		num_walls += 1
	num_walls = 1 if num_walls == 0 else num_walls
	return wall_dir/num_walls
