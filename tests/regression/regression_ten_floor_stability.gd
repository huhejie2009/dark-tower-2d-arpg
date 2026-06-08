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
		var start_floor := int(scene.get("current_floor"))
		for _i in range(10):
			scene.set("enemies_alive", 0)
			scene.call("_on_floor_cleared")
			scene.call("_enter_next_floor")
			scene.call("_enter_next_floor")
			await process_frame
		_expect(int(scene.get("current_floor")) == start_floor + 10, "ten floor transitions should advance exactly ten floors")
		_expect(scene.get("portal_available") == false, "portal should be consumed after floor transition")
		_expect(scene.get("floor_transition_locked") == false, "floor transition lock should release")
		scene.queue_free()
		await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_TEN_FLOOR_STABILITY_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
