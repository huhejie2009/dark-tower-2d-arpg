extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const TownPrepSummaryServiceScript := preload("res://scripts/data/TownPrepSummaryService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Prep", "warrior")
	player["player_level"] = 7
	player["skill_points"] = 3
	player["highest_floor"] = 12
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player.get("inventory", {})), {
		"id": "gold",
		"name": "金币",
		"type": "currency",
		"amount": 88,
	})

	var summary: Dictionary = TownPrepSummaryServiceScript.build_summary(player)
	_expect(str(summary.get("character_text", "")).contains("Prep"), "summary should include character name")
	_expect(str(summary.get("character_text", "")).contains("Lv.7"), "summary should include player level")
	_expect(str(summary.get("progress_text", "")).contains("最高层 12"), "summary should include best floor")
	_expect(str(summary.get("start_text", "")).contains("第 1 层"), "summary should show fresh run start")
	_expect(str(summary.get("start_text", "")).contains("12"), "summary should show best floor challenge")
	_expect(str(summary.get("start_text", "")).contains("最高层"), "summary should explain saved highest floor")
	_expect(str(summary.get("start_explanation_text", "")).contains("已保存进度"), "summary should expose readable start explanation")
	_expect(str(summary.get("resource_text", "")).contains("金币 88"), "summary should include inventory gold")
	_expect(str(summary.get("growth_text", "")).contains("技能点 3"), "summary should include skill points")
	_expect(int(summary.get("gear_score", 0)) > 0, "summary should expose gear score")
	_expect(int(summary.get("inventory_items", 0)) >= 2, "summary should expose inventory item count")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_TOWN_PREP_SUMMARY_SERVICE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
