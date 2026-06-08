extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const TownPrepRecommendationServiceScript := preload("res://scripts/data/TownPrepRecommendationService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Advice", "warrior")
	player["skill_points"] = 2
	player["highest_floor"] = 8
	var inventory: Dictionary = Dictionary(player.get("inventory", {})).duplicate(true)
	inventory = InventoryDataServiceScript.add_item(inventory, _equipment_payload("prep_upgrade_sword", "Prep Upgrade Sword", 6, {"attack_damage": 42}))
	for i in range(22):
		inventory = InventoryDataServiceScript.add_item(inventory, {
			"id": "prep_material_%d" % i,
			"name": "Prep Material %d" % i,
			"type": "material",
			"amount": 1,
		})
	player["inventory"] = inventory

	var result: Dictionary = TownPrepRecommendationServiceScript.build_recommendations(player)
	var items: Array = Array(result.get("items", []))
	_expect(items.size() >= 3, "prep recommendations should include multiple actionable items")
	_expect(str(result.get("recommendation_text", "")).contains("Spend SP 2"), "recommendation text should mention unspent skill points")
	_expect(str(result.get("recommendation_text", "")).contains("Equip upgrade"), "recommendation text should mention equipment upgrades")
	_expect(str(result.get("recommendation_text", "")).contains("Bag"), "recommendation text should mention bag pressure")
	_expect(_has_recommendation_id(items, "spend_skill_points"), "recommendations should expose skill point id")
	_expect(_has_recommendation_id(items, "equip_upgrade"), "recommendations should expose equipment upgrade id")
	_expect(_has_recommendation_id(items, "manage_bag"), "recommendations should expose bag id")
	_expect(bool(result.get("has_action", false)), "recommendations should report action needed")

	var clean := PlayerDataServiceScript.build_starter_player("slot_1", "Clean", "warrior")
	var clean_result: Dictionary = TownPrepRecommendationServiceScript.build_recommendations(clean)
	_expect(not bool(clean_result.get("has_action", true)), "fresh starter should not need prep actions")
	_expect(str(clean_result.get("recommendation_text", "")).contains("Ready"), "clean recommendation should say ready")
	_finish()

func _equipment_payload(id: String, item_name: String, level: int, affixes: Dictionary) -> Dictionary:
	return {
		"id": id,
		"name": item_name,
		"type": "equipment",
		"amount": 1,
		"equipment": {
			"instance_id": id,
			"name": item_name,
			"slot": "weapon",
			"equipment_pool": "warrior",
			"item_level": level,
			"rarity": "magic",
			"affixes": affixes,
		},
	}

func _has_recommendation_id(items: Array, id: String) -> bool:
	for item in items:
		if str(Dictionary(item).get("id", "")) == id:
			return true
	return false

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_TOWN_PREP_RECOMMENDATION_SERVICE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
