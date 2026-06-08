extends SceneTree

const GameScene := preload("res://scenes/Game2D.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := GameScene.instantiate()
	root.add_child(scene)
	await process_frame
	_expect(scene.has_method("_set_death_presentation_delay_for_test"), "Game2D should expose death presentation delay override")
	_expect(scene.has_method("_is_death_presentation_pending_for_test"), "Game2D should expose death presentation pending state")
	if scene.has_method("_set_death_presentation_delay_for_test"):
		scene.call("_set_death_presentation_delay_for_test", 0.20)
	var player := scene.get("player") as Node
	_expect(is_instance_valid(player), "Game2D should create player")
	if is_instance_valid(player):
		player.call("take_damage", 99999)
		await process_frame
		var overlay := scene.find_child("DeathSettlementOverlay", true, false) as CanvasLayer
		if scene.has_method("_is_death_presentation_pending_for_test"):
			_expect(scene.call("_is_death_presentation_pending_for_test") == true, "player death should enter presentation pending state")
		_expect(is_instance_valid(overlay) and not overlay.visible, "death settlement should wait for the death presentation window")
		await create_timer(0.24, true).timeout
		if scene.has_method("_is_death_presentation_pending_for_test"):
			_expect(scene.call("_is_death_presentation_pending_for_test") == false, "death presentation pending state should clear after the delay")
		_expect(is_instance_valid(overlay) and overlay.visible, "death settlement should show after death presentation delay")
	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_PLAYER_DEATH_PRESENTATION_DELAY_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
