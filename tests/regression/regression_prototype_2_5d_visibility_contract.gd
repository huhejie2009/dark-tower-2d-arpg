extends SceneTree

const PrototypeScene := preload("res://scenes/prototypes/Prototype2_5DCombatRoom.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := PrototypeScene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	_expect(scene.has_method("build_visibility_snapshot_for_test"), "prototype should expose visibility snapshot")
	if not scene.has_method("build_visibility_snapshot_for_test"):
		scene.queue_free()
		await process_frame
		_finish()
		return

	var snapshot: Dictionary = scene.call("build_visibility_snapshot_for_test")
	_expect(bool(snapshot.get("has_world_environment", false)), "prototype should have a world environment")
	_expect(bool(snapshot.get("has_key_light", false)), "prototype should have a key light")
	_expect(bool(snapshot.get("floor_has_material", false)), "floor should have visible material")
	_expect(int(snapshot.get("wall_visible_material_count", 0)) >= 4, "all walls should have visible materials")
	_expect(int(snapshot.get("column_visible_material_count", 0)) >= 2, "columns should have visible materials")
	_expect(int(snapshot.get("actor_visible_marker_count", 0)) >= 3, "player and enemies should have visible markers")
	_expect(bool(snapshot.get("exit_marker_has_material", false)), "exit marker should have visible material")
	_expect(bool(snapshot.get("has_debug_hud", false)), "prototype should have a debug HUD so the screen is not visually empty")
	_expect(bool(snapshot.get("camera_has_visible_background", false)), "camera/world should have visible background color")

	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_PROTOTYPE_2_5D_VISIBILITY_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
