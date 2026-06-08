extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/Game2D.tscn")
	_expect(packed is PackedScene, "Game2D should load")
	if packed is PackedScene:
		var scene: Node = packed.instantiate()
		root.add_child(scene)
		await process_frame
		_expect(scene.has_method("_get_visual_style_for_test"), "Game2D should expose visual style contract")
		_expect(scene.has_method("_get_room_navigation_contract_for_test"), "Game2D should expose room navigation contract")
		_expect(scene.has_method("_is_position_blocked_for_test"), "Game2D should expose blocked position check")
		if scene.has_method("_get_visual_style_for_test"):
			var style: Dictionary = Dictionary(scene.call("_get_visual_style_for_test"))
			_expect(str(style.get("room_visual_mode", "")) == "topdown_production", "room visual mode should be production-friendly top-down")
			_expect(str(style.get("environment_family", "")) == "brutalist_tower_interior", "top-down production room should use the brutalist tower interior family")
			_expect(style.get("camera_zoom", Vector2.ZERO) == Vector2(1.0, 1.0), "top-down camera should use neutral zoom")
			_expect(float(style.get("visual_vertical_compress", -1.0)) == 1.0, "top-down floor should not use pseudo-isometric vertical compression")
			_expect(bool(style.get("uses_foot_anchor_sorting", false)), "actors and props should use foot-anchor Y sorting")
		if scene.has_method("_get_room_navigation_contract_for_test"):
			var contract: Dictionary = Dictionary(scene.call("_get_room_navigation_contract_for_test"))
			_expect(int(contract.get("wall_count", 0)) >= 4, "top-down room should keep clear boundary walls")
			_expect(int(contract.get("solid_obstacle_count", 0)) >= 3, "top-down room should keep solid obstacle foot blockers")
			_expect(int(contract.get("visual_only_obstacle_count", 0)) >= 3, "top-down room should separate tall obstacle visuals from foot collision")
			_expect(bool(contract.get("footprint_colliders_only", false)), "tall props should collide only at their footprint")
		if scene.has_method("_is_position_blocked_for_test"):
			_expect(bool(scene.call("_is_position_blocked_for_test", Vector2(-360, -142), 20.0)), "pillar footprint should block foot-circle movement")
			_expect(not bool(scene.call("_is_position_blocked_for_test", Vector2(-360, -224), 20.0)), "pillar upper visual space should not block front/back movement")
		_expect(scene.find_child("TopDownFloor", true, false) != null, "top-down floor node should exist")
		_expect(scene.find_child("TopDownColumnVisual", true, false) != null, "top-down column visual should exist")
		_expect(scene.find_child("TopDownDarkCoreLightChannel", true, false) != null, "tower interior should expose the central dark-core light channel visual")
		var foot_body := scene.find_child("TopDownColumnFootprintBody", true, false)
		_expect(foot_body is StaticBody2D, "top-down column should have a footprint collision body")
		scene.queue_free()
		await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_TOPDOWN_PRODUCTION_VIEW_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
