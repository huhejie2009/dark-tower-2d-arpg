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

	_expect(scene.has_method("build_prototype_snapshot_for_test"), "prototype should expose test snapshot")
	var snapshot: Dictionary = scene.call("build_prototype_snapshot_for_test")
	_expect(str(snapshot.get("prototype_id", "")) == "2_5d_billboard_combat_room", "snapshot should identify prototype")
	_expect(bool(snapshot.get("isolated_from_main_flow", false)), "prototype should stay isolated from main flow")
	_expect(bool(snapshot.get("has_camera_3d", false)), "prototype should have Camera3D")
	_expect(bool(snapshot.get("camera_orthographic", false)), "camera should be orthographic")
	_expect(int(snapshot.get("wall_count", 0)) >= 4, "prototype should have at least four wall blockers")
	_expect(int(snapshot.get("column_count", 0)) >= 2, "prototype should have at least two columns")
	_expect(int(snapshot.get("player_count", 0)) == 1, "prototype should have one player actor")
	_expect(int(snapshot.get("enemy_count", 0)) >= 2, "prototype should have template enemies")
	_expect(str(snapshot.get("template_id", "")) != "", "prototype should report active floor template")
	_expect(bool(snapshot.get("has_exit_marker", false)), "prototype should have an exit marker")

	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_PROTOTYPE_2_5D_SCENE_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
