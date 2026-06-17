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

	_expect(scene.has_method("build_visual_grounding_snapshot_for_test"), "prototype should expose visual grounding snapshot")
	_expect(scene.has_method("set_debug_readability_markers_enabled_for_test"), "prototype should expose debug readability marker toggle")
	if not scene.has_method("build_visual_grounding_snapshot_for_test") or not scene.has_method("set_debug_readability_markers_enabled_for_test"):
		scene.queue_free()
		await process_frame
		_finish()
		return

	var initial: Dictionary = scene.call("build_visual_grounding_snapshot_for_test")
	_expect(int(initial.get("contact_shadow_count", 0)) >= 3, "player and enemies should have contact shadows")
	_expect(int(initial.get("visible_contact_shadow_count", 0)) >= 3, "contact shadows should be visible by default")
	_expect(int(initial.get("actor_visible_marker_count", 0)) >= 3, "debug readability markers should still exist for QA")
	_expect(int(initial.get("actor_visible_marker_visible_count", -1)) == 0, "debug readability markers should be hidden in normal presentation")
	_expect(not bool(initial.get("debug_readability_markers_enabled", true)), "debug readability marker toggle should default off")
	_expect(bool(initial.get("all_actor_sprites_grounded", false)), "actor sprites should report grounded visual state")
	_expect(float(initial.get("average_shadow_alpha", 0.0)) > 0.0 and float(initial.get("average_shadow_alpha", 1.0)) < 0.65, "contact shadows should use soft alpha")

	scene.call("set_debug_readability_markers_enabled_for_test", true)
	await process_frame
	var debug_enabled: Dictionary = scene.call("build_visual_grounding_snapshot_for_test")
	_expect(bool(debug_enabled.get("debug_readability_markers_enabled", false)), "debug readability marker toggle should turn on")
	_expect(int(debug_enabled.get("actor_visible_marker_visible_count", 0)) >= 3, "debug readability markers should become visible when QA toggle is on")

	scene.call("set_debug_readability_markers_enabled_for_test", false)
	await process_frame
	var debug_disabled: Dictionary = scene.call("build_visual_grounding_snapshot_for_test")
	_expect(int(debug_disabled.get("actor_visible_marker_visible_count", -1)) == 0, "debug readability markers should hide again when QA toggle is off")

	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_PROTOTYPE_2_5D_VISUAL_GROUNDING_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
