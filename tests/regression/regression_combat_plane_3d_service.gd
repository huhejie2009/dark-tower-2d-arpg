extends SceneTree

const CombatPlane3DService := preload("res://scripts/prototype/CombatPlane3DService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var origin := Vector3(0.0, 5.0, 0.0)
	var target := Vector3(3.0, -2.0, 4.0)
	_expect(is_equal_approx(CombatPlane3DService.distance_xz(origin, target), 5.0), "XZ distance should ignore Y")
	_expect(CombatPlane3DService.is_in_range_xz(origin, target, 5.0), "range check should include exact radius")
	_expect(not CombatPlane3DService.is_in_range_xz(origin, target, 4.99), "range check should reject outside radius")

	var input := CombatPlane3DService.normalize_move_input(Vector2(2.0, -2.0))
	_expect(is_equal_approx(input.length(), 1.0), "normalized input should have unit length")
	_expect(CombatPlane3DService.normalize_move_input(Vector2.ZERO) == Vector2.ZERO, "zero input should stay zero")

	var forward := Vector3(0.0, 0.0, -1.0)
	var inside := Vector3(0.0, 0.0, -3.0)
	var outside := Vector3(3.0, 0.0, 0.0)
	_expect(CombatPlane3DService.is_inside_attack_arc_xz(origin, inside, forward, 4.0, 70.0), "target in front should be inside arc")
	_expect(not CombatPlane3DService.is_inside_attack_arc_xz(origin, outside, forward, 4.0, 70.0), "target to side should be outside narrow arc")

	var snapshot := CombatPlane3DService.build_contract_snapshot()
	_expect(str(snapshot.get("plane", "")) == "xz", "snapshot should declare XZ plane")
	_expect(str(snapshot.get("collision_basis", "")) == "3d_shapes", "snapshot should declare 3D shape collision")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_COMBAT_PLANE_3D_SERVICE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
