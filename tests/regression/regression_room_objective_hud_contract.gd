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
	_expect(scene.has_method("get_room_objective_state_for_test"), "Game2D should expose objective state for QA")
	var state: Dictionary = scene.call("get_room_objective_state_for_test") if scene.has_method("get_room_objective_state_for_test") else {}
	_expect(str(state.get("hud_text", "")).contains("Objective:"), "objective state should include HUD text")
	var hud := scene.get("hud") as Node
	_expect(is_instance_valid(hud), "HUD should exist")
	if is_instance_valid(hud) and hud.has_method("get_objective_text_for_test"):
		_expect(str(hud.call("get_objective_text_for_test")).contains("Objective:"), "HUD should show objective text")
	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_ROOM_OBJECTIVE_HUD_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
