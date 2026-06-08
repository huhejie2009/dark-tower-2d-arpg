extends SceneTree

const Game2DScene := preload("res://scenes/Game2D.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := Game2DScene.instantiate()
	root.add_child(scene)
	await process_frame

	var hud := scene.find_child("HudController", true, false)
	_expect(hud != null, "Game2D should create HudController")
	if hud != null:
		_expect(hud.find_child("LevelLabel", true, false) != null, "HUD should show player level")
		_expect(hud.find_child("ExperienceBar", true, false) != null, "HUD should show experience bar")
		_expect(hud.find_child("SkillPointLabel", true, false) != null, "HUD should show skill points")

		var data: Dictionary = Dictionary(scene.get("player_data")).duplicate(true)
		data["player_level"] = 3
		data["current_exp"] = 45
		data["exp_to_next_level"] = 120
		data["skill_points"] = 2
		scene.set("player_data", data)
		if scene.has_method("_update_hud"):
			scene.call("_update_hud", "XP HUD test")
		var level_label := hud.find_child("LevelLabel", true, false) as Label
		var exp_bar := hud.find_child("ExperienceBar", true, false) as ProgressBar
		var skill_label := hud.find_child("SkillPointLabel", true, false) as Label
		if level_label != null:
			_expect(str(level_label.text).contains("Lv.3"), "HUD level label should include player level")
		if exp_bar != null:
			_expect(int(exp_bar.max_value) == 120, "HUD experience bar max should match exp_to_next_level")
			_expect(int(exp_bar.value) == 45, "HUD experience bar value should match current_exp")
		if skill_label != null:
			_expect(str(skill_label.text).contains("SP 2"), "HUD skill point label should include skill points")

	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_HUD_LEVEL_EXPERIENCE_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
