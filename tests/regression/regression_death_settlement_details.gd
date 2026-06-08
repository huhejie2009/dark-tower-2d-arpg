extends SceneTree

const GameScene := preload("res://scenes/Game2D.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := GameScene.instantiate()
	root.add_child(scene)
	await process_frame
	_expect(scene.has_method("_build_death_summary_text_for_test"), "Game2D should expose death summary text builder")
	if scene.has_method("_build_death_summary_text_for_test"):
		scene.set("current_floor", 5)
		scene.set("current_floor_template", {"template_id": "boss_gatekeeper"})
		scene.set("floor_kill_count", 3)
		var pickups: Array[String] = ["Gold", "Boss Sword"]
		scene.set("floor_pickup_names", pickups)
		scene.set("last_floor_rewards", {"is_boss_floor": true, "guaranteed_items": [{"name": "Boss Sword"}]})
		var text := str(scene.call("_build_death_summary_text_for_test"))
		_expect(text.contains("boss_gatekeeper"), "death summary should include floor template id")
		_expect(text.contains("Kills: 3"), "death summary should include kill count")
		_expect(text.contains("Gold") and text.contains("Boss Sword"), "death summary should include picked items")
		_expect(text.contains("Boss reward"), "death summary should mention boss reward")
	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_DEATH_SETTLEMENT_DETAILS_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
