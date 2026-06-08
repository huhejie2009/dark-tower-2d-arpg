extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const InventoryEquipmentWindowScript := preload("res://scripts/ui/InventoryEquipmentWindow.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Test", "warrior")
	var boss_weapon := {
		"instance_id": "boss_rare_weapon",
		"name": "Gatekeeper Rare Blade",
		"slot": "weapon",
		"equipment_pool": "warrior",
		"item_level": 12,
		"rarity": "rare",
		"affixes": {"attack_damage": 48},
	}
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player["inventory"]), {
		"id": "boss_rare_weapon",
		"name": "Gatekeeper Rare Blade",
		"type": "equipment",
		"source": "boss",
		"loot_quality": {
			"source": "boss",
			"quality_tag": "boss_floor_10",
			"item_level": 12,
			"guaranteed_equipment": true,
		},
		"equipment": boss_weapon,
	})

	var window := InventoryEquipmentWindowScript.new()
	root.add_child(window)
	window.set_player_data(player)
	await process_frame

	_expect(window.has_method("get_item_recommendation_for_test"), "window should expose recommendation metadata for tests")
	if window.has_method("get_item_recommendation_for_test"):
		var recommendation: Dictionary = Dictionary(window.call("get_item_recommendation_for_test", "boss_rare_weapon"))
		_expect(bool(recommendation.get("upgrade", false)), "boss weapon should be recommended as an upgrade")
		_expect(int(recommendation.get("score_delta", 0)) > 0, "recommendation should expose positive score delta")
		_expect(str(recommendation.get("source_label", "")) == "Boss reward", "recommendation should expose readable boss source")
		_expect(str(recommendation.get("quality_tag", "")) == "boss_floor_10", "recommendation should preserve loot quality tag")

	var visual_meta: Dictionary = Dictionary(window.call("get_item_visual_metadata_for_test", "boss_rare_weapon"))
	_expect(str(visual_meta.get("recommendation_rank", "")) in ["minor", "strong", "major"], "visual metadata should expose recommendation rank")
	_expect(int(visual_meta.get("score_delta", 0)) > 0, "visual metadata should expose score delta")
	_expect(str(visual_meta.get("source_label", "")) == "Boss reward", "visual metadata should expose source label")
	_expect(str(visual_meta.get("quality_tag", "")) == "boss_floor_10", "visual metadata should expose quality tag")
	_expect(str(visual_meta.get("badge", "")) == "+", "recommended upgrade should keep upgrade badge")

	window.call("select_item", "boss_rare_weapon")
	await process_frame
	var detail := str(window.find_child("ItemDetail", true, false).get("text"))
	_expect(detail.contains("Source: Boss reward"), "detail should include readable source")
	_expect(detail.contains("Quality: boss_floor_10"), "detail should include quality tag")
	_expect(detail.contains("Recommendation:"), "detail should include recommendation text")
	_expect(detail.contains("Score Delta: +"), "detail should include signed score delta")

	window.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_INVENTORY_RECOMMENDATION_TAGS_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
