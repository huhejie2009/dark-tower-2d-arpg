extends SceneTree

const Game2DScene := preload("res://scenes/Game2D.tscn")

func _initialize() -> void:
	var scene := Game2DScene.instantiate()
	root.add_child(scene)
	await process_frame

	_expect(scene.has_method("_find_safe_spawn_position_for_test"), "Game2D should expose safe spawn position lookup")
	_expect(scene.has_method("_is_position_blocked_for_test"), "Game2D should expose blocked position check")
	_expect(scene.has_method("_spawn_portal_for_test"), "Game2D should expose portal spawn for safe spawn tests")

	if scene.has_method("_find_safe_spawn_position_for_test") and scene.has_method("_is_position_blocked_for_test"):
		var blocked_point := Vector2(510, 125)
		_expect(bool(scene.call("_is_position_blocked_for_test", blocked_point, 24.0)), "test fixture point should be inside a solid obstacle")
		var safe_point: Vector2 = scene.call("_find_safe_spawn_position_for_test", blocked_point, 24.0)
		_expect(not bool(scene.call("_is_position_blocked_for_test", safe_point, 24.0)), "safe spawn lookup should move blocked points away from obstacles")
		_expect(safe_point.distance_to(blocked_point) > 32.0, "safe spawn lookup should actually move unsafe points")

		var open_point := Vector2(0, 180)
		var unchanged: Vector2 = scene.call("_find_safe_spawn_position_for_test", open_point, 24.0)
		_expect(unchanged.distance_to(open_point) < 0.01, "safe spawn lookup should keep already safe points unchanged")

		for enemy in get_nodes_in_group("enemies"):
			var enemy_2d := enemy as Node2D
			if enemy_2d != null:
				_expect(not bool(scene.call("_is_position_blocked_for_test", enemy_2d.global_position, 24.0)), "spawned enemy should not start inside an obstacle at %s" % str(enemy_2d.global_position))

	if scene.has_method("_spawn_portal_for_test") and scene.has_method("_is_position_blocked_for_test"):
		scene.call("_spawn_portal_for_test")
		await process_frame
		var portal := scene.find_child("NextFloorPortal", true, false) as Node2D
		_expect(portal != null, "portal should spawn for safe spawn test")
		if portal != null:
			_expect(not bool(scene.call("_is_position_blocked_for_test", portal.global_position, 52.0)), "portal should not spawn inside an obstacle")

	scene.queue_free()
	await process_frame
	print("NEW_PROJECT_PSEUDO_34_SAFE_SPAWN_POINTS_OK")
	quit(0)

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
