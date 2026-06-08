extends SceneTree

const Game2DScene := preload("res://scenes/Game2D.tscn")
const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := Game2DScene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var player := PlayerDataServiceScript.build_starter_player("slot_1", "P2 Metrics", "warrior")
	player["skill_points"] = 2
	scene.set("player_data", player)

	_expect(scene.has_method("_get_p2_loot_loop_metrics_for_test"), "Game2D should expose P2 loot loop metrics snapshot")
	_expect(scene.has_method("_get_p2_loot_loop_report_for_test"), "Game2D should expose P2 loot loop acceptance report")
	_expect(scene.has_method("_set_p2_loot_loop_elapsed_seconds_for_test"), "Game2D should expose P2 elapsed seconds test hook")

	if scene.has_method("_set_p2_loot_loop_elapsed_seconds_for_test"):
		scene.call("_set_p2_loot_loop_elapsed_seconds_for_test", 602.0)

	var payload := {
		"id": "better_weapon",
		"name": "Better Sword",
		"type": "equipment",
		"amount": 1,
		"equipment": {
			"instance_id": "better_weapon",
			"name": "Better Sword",
			"slot": "weapon",
			"equipment_pool": "warrior",
			"item_level": 4,
			"rarity": "magic",
			"affixes": {"attack_damage": 28},
		},
	}
	if scene.has_method("_on_drop_collected"):
		scene.call("_on_drop_collected", payload)
		await process_frame
	if scene.has_method("_clear_floor_for_test"):
		scene.call("_clear_floor_for_test")
		await process_frame

	var updated := Dictionary(scene.get("player_data")).duplicate(true)
	updated["equipped_items"] = {"weapon": "better_weapon", "armor": "", "gloves": "", "ring": ""}
	updated["unlocked_skill_nodes"] = {"vitality_training": 1}
	if scene.has_method("_on_player_data_changed"):
		scene.call("_on_player_data_changed", updated)
		await process_frame

	if scene.has_method("_get_p2_loot_loop_metrics_for_test"):
		var metrics: Dictionary = Dictionary(scene.call("_get_p2_loot_loop_metrics_for_test"))
		_expect(int(metrics.get("minutes_played", 0)) == 10, "Game2D metrics should track elapsed minutes")
		_expect(int(metrics.get("items_picked", 0)) >= 1, "Game2D metrics should count collected items")
		_expect(int(metrics.get("equipment_picked", 0)) >= 1, "Game2D metrics should count equipment pickups")
		_expect(int(metrics.get("upgrade_candidates_seen", 0)) >= 1, "Game2D metrics should count upgrade notifications")
		_expect(int(metrics.get("floors_cleared", 0)) == 1, "Game2D metrics should count cleared floors")
		_expect(int(metrics.get("equipment_changes", 0)) == 1, "Game2D metrics should count equipment changes")
		_expect(int(metrics.get("skill_upgrades", 0)) == 1, "Game2D metrics should count skill upgrades")

	if scene.has_method("_get_p2_loot_loop_report_for_test"):
		var report: Dictionary = Dictionary(scene.call("_get_p2_loot_loop_report_for_test"))
		_expect(str(report.get("phase_id", "")) == "P2", "Game2D P2 report should come from acceptance service")
		_expect(str(report.get("summary_text", "")) != "", "Game2D P2 report should include a summary")

	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("FOCUSED_GAME2D_P2_LOOT_LOOP_METRICS_BRIDGE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
