extends SceneTree

const PrototypeScene := preload("res://scenes/prototypes/Prototype2_5DCombatRoom.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := PrototypeScene.instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame

	_expect(scene.has_method("build_player_control_snapshot_for_test"), "prototype should expose player control snapshot")
	_expect(scene.has_method("set_player_move_input_for_test"), "prototype should expose deterministic test input")
	if not scene.has_method("build_player_control_snapshot_for_test") or not scene.has_method("set_player_move_input_for_test"):
		scene.queue_free()
		await process_frame
		_finish()
		return

	var before: Dictionary = scene.call("build_player_control_snapshot_for_test")
	_expect(bool(before.get("can_control_player", false)), "player should be controllable")
	_expect(str(before.get("movement_plane", "")) == "xz", "player should move on XZ plane")
	_expect(float(before.get("player_movement_speed", 0.0)) > 0.0, "prototype player should have readable 3D movement speed")
	_expect(bool(before.get("camera_current", false)), "prototype camera should be current")
	_expect(bool(before.get("camera_orthographic", false)), "prototype camera should remain orthographic")
	_expect(bool(before.get("camera_tracks_player", false)), "camera should track player")

	var before_player_position: Vector3 = before.get("player_position", Vector3.ZERO)
	var before_camera_position: Vector3 = before.get("camera_position", Vector3.ZERO)

	scene.call("set_player_move_input_for_test", Vector2.RIGHT)
	for index in range(10):
		await physics_frame

	var after_right: Dictionary = scene.call("build_player_control_snapshot_for_test")
	var after_player_position: Vector3 = after_right.get("player_position", Vector3.ZERO)
	var after_camera_position: Vector3 = after_right.get("camera_position", Vector3.ZERO)
	_expect(after_player_position.x > before_player_position.x + 0.05, "right input should move player along +X")
	_expect(absf(after_player_position.y - before_player_position.y) <= 0.01, "player movement should not drift on Y")
	_expect(absf(after_player_position.z - before_player_position.z) <= 0.05, "right input should not significantly change Z")
	_expect(str(after_right.get("player_facing_direction", "")) == "right", "right input should update player facing")
	_expect(after_camera_position.x > before_camera_position.x + 0.05, "camera should follow player along X")

	scene.call("set_player_move_input_for_test", Vector2.ZERO)
	await physics_frame
	var stopped: Dictionary = scene.call("build_player_control_snapshot_for_test")
	_expect(Vector2(stopped.get("active_move_input", Vector2.ONE)).length_squared() <= 0.0001, "zero input should stop movement input")

	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_PROTOTYPE_2_5D_PLAYER_MOVEMENT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
