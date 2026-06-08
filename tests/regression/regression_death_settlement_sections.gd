extends SceneTree

const GameScene := preload("res://scenes/Game2D.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := GameScene.instantiate()
	root.add_child(scene)
	await process_frame
	_expect(scene.find_child("DeathFloorSection", true, false) != null, "death settlement should have floor section")
	_expect(scene.find_child("DeathKillsSection", true, false) != null, "death settlement should have kills section")
	_expect(scene.find_child("DeathLootSection", true, false) != null, "death settlement should have loot section")
	_expect(scene.find_child("DeathBossRewardSection", true, false) != null, "death settlement should have boss reward section")
	_expect(scene.has_method("_refresh_death_settlement_sections_for_test"), "Game2D should expose death settlement section refresh")
	if scene.has_method("_refresh_death_settlement_sections_for_test"):
		scene.set("current_floor", 5)
		scene.set("current_floor_template", {"template_id": "boss_gatekeeper"})
		scene.set("floor_kill_count", 4)
		var pickups: Array[String] = ["Gold", "Gatekeeper Trophy 5"]
		scene.set("floor_pickup_names", pickups)
		scene.set("last_floor_rewards", {"is_boss_floor": true, "guaranteed_items": [{"name": "Gatekeeper Trophy 5"}]})
		scene.call("_refresh_death_settlement_sections_for_test")
		_expect(str(scene.find_child("DeathFloorSection", true, false).get("text")).contains("boss_gatekeeper"), "floor section should show template")
		_expect(str(scene.find_child("DeathKillsSection", true, false).get("text")).contains("4"), "kills section should show kill count")
		_expect(str(scene.find_child("DeathLootSection", true, false).get("text")).contains("Gold"), "loot section should show picked item")
		_expect(str(scene.find_child("DeathBossRewardSection", true, false).get("text")).contains("Gatekeeper Trophy 5"), "boss section should show boss reward")
	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_DEATH_SETTLEMENT_SECTIONS_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
