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
		_expect(hud.find_child("HealthLabel", true, false) != null, "HUD should show health label")
		_expect(hud.find_child("HealthBar", true, false) != null, "HUD should show health bar")
		_expect(hud.find_child("ManaLabel", true, false) != null, "HUD should show mana label")
		_expect(hud.find_child("ManaBar", true, false) != null, "HUD should show mana bar")

		var data: Dictionary = Dictionary(scene.get("player_data")).duplicate(true)
		data["health"] = 73
		data["max_health"] = 130
		data["mana"] = 21
		data["max_mana"] = 45
		if scene.has_method("_on_player_data_changed"):
			scene.call("_on_player_data_changed", data)
		else:
			scene.set("player_data", data)
		if scene.has_method("_update_hud"):
			scene.call("_update_hud", "Vitals HUD test")
		var health_label := hud.find_child("HealthLabel", true, false) as Label
		var health_bar := hud.find_child("HealthBar", true, false) as ProgressBar
		var mana_label := hud.find_child("ManaLabel", true, false) as Label
		var mana_bar := hud.find_child("ManaBar", true, false) as ProgressBar
		if health_label != null:
			_expect(str(health_label.text).contains("HP 73/130"), "health label should show current and max health")
		if health_bar != null:
			_expect(int(health_bar.max_value) == 130, "health bar max should match max health")
			_expect(int(health_bar.value) == 73, "health bar value should match current health")
		if mana_label != null:
			_expect(str(mana_label.text).contains("MP 21/45"), "mana label should show current and max mana")
		if mana_bar != null:
			_expect(int(mana_bar.max_value) == 45, "mana bar max should match max mana")
			_expect(int(mana_bar.value) == 21, "mana bar value should match current mana")

	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_HUD_VITALS_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
