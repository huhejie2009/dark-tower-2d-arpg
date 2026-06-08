extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const InventoryEquipmentWindowScript := preload("res://scripts/ui/InventoryEquipmentWindow.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Compare Summary", "warrior")
	var better_weapon := {
		"instance_id": "better_weapon",
		"name": "Better Sword",
		"slot": "weapon",
		"equipment_pool": "warrior",
		"item_level": 4,
		"rarity": "magic",
		"affixes": {"attack_damage": 28, "critical_chance": 2},
	}
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player["inventory"]), {
		"id": "better_weapon",
		"name": "Better Sword",
		"type": "equipment",
		"equipment": better_weapon,
	})

	var window := InventoryEquipmentWindowScript.new()
	root.add_child(window)
	window.set_player_data(player)
	await process_frame

	_expect(window.has_method("get_item_compare_summary_for_test"), "window should expose structured compare summary")
	if window.has_method("get_item_compare_summary_for_test"):
		var summary: Dictionary = Dictionary(window.call("get_item_compare_summary_for_test", "better_weapon"))
		_expect(str(summary.get("slot", "")) == "weapon", "summary should expose compared slot")
		_expect(str(summary.get("candidate_item_id", "")) == "better_weapon", "summary should expose candidate id")
		_expect(str(summary.get("equipped_item_id", "")) != "", "summary should expose equipped item id")
		_expect(int(summary.get("candidate_score", 0)) > int(summary.get("equipped_score", 0)), "summary should expose score improvement")
		_expect(int(summary.get("score_delta", 0)) > 0, "summary should expose positive score delta")
		_expect(str(summary.get("headline", "")).contains("Upgrade"), "summary headline should flag upgrade")
		var stat_deltas: Array = Array(summary.get("stat_deltas", []))
		_expect(stat_deltas.size() >= 2, "summary should expose stat delta rows")
		var found_attack := false
		var found_crit := false
		for row in stat_deltas:
			var delta_row: Dictionary = Dictionary(row)
			if str(delta_row.get("stat_id", "")) == "attack_damage":
				found_attack = true
				_expect(int(delta_row.get("delta", 0)) > 0, "attack delta should be positive")
				_expect(str(delta_row.get("compact_text", "")).contains("+"), "attack row should expose compact text")
			if str(delta_row.get("stat_id", "")) == "critical_chance":
				found_crit = true
				_expect(int(delta_row.get("delta", 0)) > 0, "crit delta should be positive")
		_expect(found_attack, "summary should include attack damage delta")
		_expect(found_crit, "summary should include critical chance delta")
		_expect(str(summary.get("compact_text", "")).contains("Score +"), "summary should expose compact score text")

	var detail := str(window.call("describe_item_for_test", "better_weapon"))
	_expect(detail.contains("Compare Summary:"), "detail should include compact compare summary section")
	_expect(detail.contains("Score +"), "detail should include score delta text")
	_expect(detail.contains("critical_chance"), "detail should include non-overlapping stat gains")

	window.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_EQUIPMENT_COMPARE_SUMMARY_SERVICE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
