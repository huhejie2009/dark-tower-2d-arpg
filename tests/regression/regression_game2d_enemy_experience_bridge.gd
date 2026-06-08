extends SceneTree

const Game2DScene := preload("res://scenes/Game2D.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := Game2DScene.instantiate()
	root.add_child(scene)
	await process_frame
	_expect(scene.has_method("_award_enemy_experience_for_test"), "Game2D should expose enemy experience award test hook")
	if scene.has_method("_award_enemy_experience_for_test"):
		var before: Dictionary = Dictionary(scene.get("player_data")).duplicate(true)
		before["current_exp"] = 0
		before["exp_to_next_level"] = 100
		before["player_level"] = 1
		scene.set("player_data", before)
		var result: Dictionary = scene.call("_award_enemy_experience_for_test", {
			"enemy_type": "rot_melee",
			"display_rank": "normal",
			"is_elite": false,
			"is_boss": false,
		})
		var after: Dictionary = Dictionary(scene.get("player_data"))
		_expect(int(result.get("experience_gained", 0)) > 0, "enemy death should award positive experience")
		_expect(int(after.get("current_exp", 0)) > 0, "player data should store gained experience")
		_expect(int(after.get("player_level", 1)) >= 1, "experience award should preserve player level")
	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_GAME2D_ENEMY_EXPERIENCE_BRIDGE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
