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

	_expect(scene.has_method("build_visual_qa_snapshot_for_test"), "prototype should expose visual QA snapshot")
	if not scene.has_method("build_visual_qa_snapshot_for_test"):
		scene.queue_free()
		await process_frame
		_finish()
		return
	var snapshot: Dictionary = scene.call("build_visual_qa_snapshot_for_test")
	_expect(str(snapshot.get("qa_id", "")) == "prototype_2_5d_visual_readability", "snapshot should identify visual QA")
	_expect(bool(snapshot.get("camera_has_readable_angle", false)), "camera angle should be accepted")
	_expect(bool(snapshot.get("room_has_boundaries", false)), "room should expose boundaries")
	_expect(bool(snapshot.get("actors_have_billboard_contract", false)), "actors should expose billboard contract")
	_expect(bool(snapshot.get("columns_have_collision_footprint", false)), "columns should have collision footprint")
	_expect(bool(snapshot.get("main_flow_untouched", false)), "prototype should confirm main flow remains untouched")

	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_PROTOTYPE_2_5D_VISUAL_QA_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
