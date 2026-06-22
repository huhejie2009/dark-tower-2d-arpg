extends SceneTree

const Game2DScript := preload("res://scripts/app/Game2D.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := Game2DScript.new()
	root.add_child(game)
	await process_frame
	_expect(game.has_method("set_combat_control_mode_for_test"), "Game2D should expose auto mode test setter")
	game.call("set_combat_control_mode_for_test", "auto")
	_expect(str(game.call("get_combat_control_mode_for_test")) == "auto", "Game2D should switch to auto mode")
	await process_frame
	_expect(game.get("player") != null, "Game2D player should remain valid in auto mode")
	game.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_GAME2D_AUTO_COMBAT_MODE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
