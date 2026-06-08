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
		_expect(scene.find_child("DeathSettlementOverlay", true, false) != null, "death settlement overlay should exist")
		_expect(scene.find_child("DeathReturnTownButton", true, false) != null, "death return button should exist")
		var player := scene.get("player") as Node
		if is_instance_valid(player):
			if scene.has_method("_set_death_presentation_delay_for_test"):
				scene.call("_set_death_presentation_delay_for_test", 0.01)
			player.call("take_damage", 99999)
			await create_timer(0.04, true).timeout
			var overlay := scene.find_child("DeathSettlementOverlay", true, false) as CanvasLayer
			_expect(is_instance_valid(overlay) and overlay.visible, "death settlement should become visible after death")
			_expect(scene.get("transition_locked") == false, "death settlement should not immediately lock scene transition")
		scene.queue_free()
		await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_DEATH_SETTLEMENT_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
