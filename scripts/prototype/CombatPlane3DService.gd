extends RefCounted

static func distance_xz(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

static func is_in_range_xz(a: Vector3, b: Vector3, radius: float) -> bool:
	return distance_xz(a, b) <= maxf(radius, 0.0)

static func normalize_move_input(input: Vector2) -> Vector2:
	if input.length_squared() <= 0.0001:
		return Vector2.ZERO
	return input.normalized()

static func vector3_from_move_input(input: Vector2, speed: float) -> Vector3:
	var normalized := normalize_move_input(input)
	return Vector3(normalized.x * speed, 0.0, normalized.y * speed)

static func is_inside_attack_arc_xz(origin: Vector3, target: Vector3, forward: Vector3, radius: float, half_angle_degrees: float) -> bool:
	if not is_in_range_xz(origin, target, radius):
		return false
	var to_target := Vector2(target.x - origin.x, target.z - origin.z)
	if to_target.length_squared() <= 0.0001:
		return true
	var forward_xz := Vector2(forward.x, forward.z)
	if forward_xz.length_squared() <= 0.0001:
		forward_xz = Vector2(0.0, -1.0)
	var angle := rad_to_deg(absf(forward_xz.normalized().angle_to(to_target.normalized())))
	return angle <= maxf(half_angle_degrees, 0.0)

static func build_contract_snapshot() -> Dictionary:
	return {
		"plane": "xz",
		"height_axis": "y",
		"collision_basis": "3d_shapes",
		"pickup_basis": "xz_distance",
		"attack_basis": "xz_arc_or_radius",
	}
