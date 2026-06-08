extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const EquipmentDataServiceScript := preload("res://scripts/data/EquipmentDataService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Test", "warrior")
	var starter_weapon_id := str(Dictionary(player.get("equipped_items", {})).get("weapon", ""))
	var better_weapon := {
		"instance_id": "better_weapon",
		"name": "Better Sword",
		"slot": "weapon",
		"equipment_pool": "warrior",
		"item_level": 4,
		"rarity": "magic",
		"affixes": {"attack_damage": 28},
	}
	var weaker_weapon := {
		"instance_id": "weaker_weapon",
		"name": "Weaker Sword",
		"slot": "weapon",
		"equipment_pool": "warrior",
		"item_level": 1,
		"rarity": "common",
		"affixes": {"attack_damage": 1},
	}
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player["inventory"]), {
		"id": "better_weapon",
		"name": "Better Sword",
		"type": "equipment",
		"equipment": better_weapon,
	})
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player["inventory"]), {
		"id": "weaker_weapon",
		"name": "Weaker Sword",
		"type": "equipment",
		"equipment": weaker_weapon,
	})

	var equipment_service := EquipmentDataServiceScript.new()
	_expect(equipment_service.has_method("get_equipment_score"), "EquipmentDataService should expose get_equipment_score")
	_expect(equipment_service.has_method("get_item_score"), "EquipmentDataService should expose get_item_score")
	_expect(equipment_service.has_method("is_equipped_item"), "EquipmentDataService should expose is_equipped_item")
	_expect(equipment_service.has_method("is_upgrade_candidate"), "EquipmentDataService should expose is_upgrade_candidate")

	if equipment_service.has_method("get_equipment_score"):
		_expect(int(equipment_service.call("get_equipment_score", better_weapon)) > int(equipment_service.call("get_equipment_score", weaker_weapon)), "better equipment should score higher")
	if equipment_service.has_method("get_item_score"):
		_expect(int(equipment_service.call("get_item_score", player, "better_weapon")) > int(equipment_service.call("get_item_score", player, starter_weapon_id)), "better inventory item should outscore starter weapon")
	if equipment_service.has_method("is_equipped_item"):
		_expect(bool(equipment_service.call("is_equipped_item", player, starter_weapon_id)), "starter weapon should be recognized as equipped")
		_expect(not bool(equipment_service.call("is_equipped_item", player, "better_weapon")), "candidate weapon should not be recognized as equipped")
	if equipment_service.has_method("is_upgrade_candidate"):
		_expect(bool(equipment_service.call("is_upgrade_candidate", player, "better_weapon")), "stronger same-slot item should be upgrade candidate")
		_expect(not bool(equipment_service.call("is_upgrade_candidate", player, "weaker_weapon")), "weaker same-slot item should not be upgrade candidate")
		_expect(not bool(equipment_service.call("is_upgrade_candidate", player, starter_weapon_id)), "already equipped item should not be upgrade candidate")

	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_EQUIPMENT_SCORE_SERVICE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
