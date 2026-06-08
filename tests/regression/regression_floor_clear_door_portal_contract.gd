extends SceneTree

const Game2DScene := preload("res://scenes/Game2D.tscn")

func _initialize() -> void:
	var scene := Game2DScene.instantiate()
	root.add_child(scene)
	await process_frame

	_expect(scene.has_method("_clear_floor_for_test"), "Game2D should expose floor clear trigger for door tests")
	_expect(scene.has_method("_get_active_exit_door_position_for_test"), "Game2D should expose active exit door position")

	var south_door := scene.find_child("TopDownSouthDoor", true, false) as Polygon2D
	_expect(south_door != null, "front exit door should exist")
	if south_door != null:
		_expect(not bool(south_door.get_meta("active", false)), "south door should start inactive")

	if scene.has_method("_clear_floor_for_test"):
		scene.call("_clear_floor_for_test")
		await process_frame

	south_door = scene.find_child("TopDownSouthDoor", true, false) as Polygon2D
	var portal := scene.find_child("NextFloorPortal", true, false) as Node2D
	_expect(south_door != null and bool(south_door.get_meta("active", false)), "south door should activate after floor clear")
	_expect(portal != null, "portal should spawn after floor clear")
	if portal != null and scene.has_method("_get_active_exit_door_position_for_test"):
		var door_position: Vector2 = scene.call("_get_active_exit_door_position_for_test")
		_expect(portal.global_position.distance_to(door_position) <= 96.0, "portal should spawn near active exit door")

	scene.queue_free()
	await process_frame
	print("NEW_PROJECT_FLOOR_CLEAR_DOOR_PORTAL_CONTRACT_OK")
	quit(0)

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
