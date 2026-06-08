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
		_expect(scene.find_child("PauseOverlay", true, false) != null, "PauseOverlay should exist")
		_expect(scene.find_child("ReturnTownButton", true, false) != null, "ReturnTownButton should exist")
		_expect(scene.get("transition_locked") == false, "transition should start unlocked")
		if not scene.has_method("_lock_transition"):
			_expect(false, "Game2D should expose _lock_transition")
		else:
			scene.call("_lock_transition")
			_expect(scene.get("transition_locked") == true, "transition lock should be settable")
		scene.queue_free()
		await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_GAME2D_PAUSE_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
