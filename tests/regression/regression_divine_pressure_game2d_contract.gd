extends SceneTree

const GameScene := preload("res://scenes/Game2D.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := GameScene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	_expect(scene.has_method("trigger_divine_pressure_for_test"), "Game2D should expose divine pressure test trigger")
	if scene.has_method("trigger_divine_pressure_for_test"):
		scene.call("trigger_divine_pressure_for_test", Vector2.ZERO, "elite_defeated")
	await process_frame
	_expect(scene.has_method("get_divine_pressure_state_for_test"), "Game2D should expose divine pressure state")
	var state: Dictionary = scene.call("get_divine_pressure_state_for_test") if scene.has_method("get_divine_pressure_state_for_test") else {}
	_expect(bool(state.get("active", false)), "pressure should be active during warning")
	_expect(float(state.get("warning_seconds", 0.0)) >= 0.6, "pressure warning should be readable")
	_expect(scene.get_node_or_null("ArenaRoot/DivinePressureWarning") != null, "warning VFX node should exist")
	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_DIVINE_PRESSURE_GAME2D_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
