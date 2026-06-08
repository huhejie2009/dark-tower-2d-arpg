extends SceneTree

const Game2DScene := preload("res://scenes/Game2D.tscn")

func _initialize() -> void:
	var scene := Game2DScene.instantiate()
	root.add_child(scene)
	await process_frame

	_expect(scene.has_method("_get_room_navigation_contract_for_test"), "Game2D should expose room navigation contract")
	if scene.has_method("_get_room_navigation_contract_for_test"):
		var contract: Dictionary = scene.call("_get_room_navigation_contract_for_test")
		_expect(int(contract.get("door_count", 0)) >= 2, "top-down room should have at least two readable doors")
		_expect(int(contract.get("wall_count", 0)) >= 4, "top-down room should have thick wall visuals")
		_expect(int(contract.get("solid_obstacle_count", 0)) >= 3, "top-down room should have solid obstacle footprints")
		_expect(int(contract.get("visual_only_obstacle_count", 0)) >= 3, "top-down room should separate tall visuals from footprint collision")
		_expect(int(contract.get("elevated_layer_count", 0)) >= 3, "top-down room should have occlusion scene layers")
		_expect(bool(contract.get("obstacles_collide", false)), "top-down obstacle footprints should use collision bodies")
		_expect(bool(contract.get("footprint_colliders_only", false)), "top-down tall props should collide only at their footprints")

	_expect(scene.find_child("TopDownNorthDoor", true, false) != null, "room should show a back door")
	_expect(scene.find_child("TopDownSouthDoor", true, false) != null, "room should show a front exit door")
	_expect(scene.find_child("TopDownBackWallVisual", true, false) != null, "room should show a back wall visual")
	_expect(scene.find_child("TopDownForegroundConcreteEdge", true, false) != null, "room should show a foreground occluder")

	var obstacle_body := scene.find_child("TopDownColumnFootprintBody", true, false)
	_expect(obstacle_body is StaticBody2D, "column footprints should have StaticBody2D collision")
	if obstacle_body is StaticBody2D:
		_expect(obstacle_body.find_child("CollisionShape2D", true, false) != null, "column footprint should have a collision shape")

	var enemy := scene.find_child("Enemy2D", true, false)
	_expect(enemy != null, "enemy should exist")
	if enemy != null:
		_expect(enemy.has_method("_build_chase_velocity_for_test"), "Enemy2D should expose chase velocity for obstacle avoidance tests")
		if enemy.has_method("_build_chase_velocity_for_test"):
			var velocity: Vector2 = enemy.call("_build_chase_velocity_for_test", Vector2.RIGHT, true)
			_expect(velocity.y != 0.0, "enemy chase velocity should add a side step when obstacle contact is detected")

	scene.queue_free()
	await process_frame
	print("NEW_PROJECT_TOPDOWN_ROOM_NAVIGATION_CONTRACT_OK")
	quit(0)

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
