extends SceneTree

const Game2DScene := preload("res://scenes/Game2D.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := Game2DScene.instantiate()
	root.add_child(scene)
	await process_frame

	_expect(scene.has_method("_get_collision_layout_for_test"), "Game2D should expose collision layout contract")
	if scene.has_method("_get_collision_layout_for_test"):
		var contract: Dictionary = Dictionary(scene.call("_get_collision_layout_for_test"))
		_expect(str(contract.get("environment_family", "")) == "brutalist_tower_interior", "collision layout should match tower interior environment")
		_expect(int(contract.get("boundary_body_count", 0)) >= 4, "tower room should have real boundary wall collision bodies")
		_expect(int(contract.get("footprint_body_count", 0)) >= 4, "tower room should have column/ruin footprint blockers aligned to the background")
		_expect(bool(contract.get("uses_footprint_only_obstacles", false)), "tall props should still collide only at their floor footprint")
		_expect(bool(contract.get("center_lane_clear", false)), "central combat lane should remain clear for movement and combat")

	_expect(scene.find_child("TopDownNorthWallBody", true, false) is StaticBody2D, "north wall should have a StaticBody2D")
	_expect(scene.find_child("TopDownSouthWallBody", true, false) is StaticBody2D, "south wall should have a StaticBody2D")
	_expect(scene.find_child("TopDownWestWallBody", true, false) is StaticBody2D, "west wall should have a StaticBody2D")
	_expect(scene.find_child("TopDownEastWallBody", true, false) is StaticBody2D, "east wall should have a StaticBody2D")

	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_TOWER_ROOM_COLLISION_LAYOUT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
