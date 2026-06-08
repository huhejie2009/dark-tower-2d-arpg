extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const EquipmentActionHintServiceScript := preload("res://scripts/data/EquipmentActionHintService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Hint", "warrior")
	var inventory: Dictionary = Dictionary(player.get("inventory", {})).duplicate(true)
	inventory = InventoryDataServiceScript.add_item(inventory, _equipment_payload("better_sword", "Better Sword", "warrior", 6, {"attack_damage": 34}))
	inventory = InventoryDataServiceScript.add_item(inventory, _equipment_payload("weaker_sword", "Weaker Sword", "warrior", 1, {"attack_damage": 1}, "common"))
	inventory = InventoryDataServiceScript.add_item(inventory, _equipment_payload("ranger_bow", "Ranger Bow", "ranger", 8, {"attack_damage": 80}))
	player["inventory"] = inventory

	var better: Dictionary = EquipmentActionHintServiceScript.build_hint(player, "better_sword")
	_expect(bool(better.get("can_equip", false)), "better warrior sword should be equippable")
	_expect(bool(better.get("upgrade", false)), "better warrior sword should be marked as upgrade")
	_expect(str(better.get("button_text", "")).contains("+"), "upgrade button should expose score delta")
	_expect(str(better.get("primary_text", "")).contains("Can equip"), "equippable hint should say Can equip")

	var weaker: Dictionary = EquipmentActionHintServiceScript.build_hint(player, "weaker_sword")
	_expect(bool(weaker.get("can_equip", false)), "weaker warrior sword should still be equippable")
	_expect(not bool(weaker.get("upgrade", true)), "weaker sword should not be marked as upgrade")
	_expect(str(weaker.get("primary_text", "")).contains("Lower score"), "weaker hint should call out lower score")

	var blocked: Dictionary = EquipmentActionHintServiceScript.build_hint(player, "ranger_bow")
	_expect(not bool(blocked.get("can_equip", true)), "wrong class equipment should not be equippable")
	_expect(str(blocked.get("reason", "")) == "wrong_class", "wrong class reason should be preserved")
	_expect(str(blocked.get("button_text", "")) == "Class blocked", "blocked button should explain class block")
	_expect(str(blocked.get("primary_text", "")).contains("Wrong class"), "blocked hint should be readable")

	var equipped: Dictionary = EquipmentActionHintServiceScript.build_hint(player, "starter_warrior_sword")
	_expect(bool(equipped.get("equipped", false)), "starter weapon should be marked equipped")
	_expect(str(equipped.get("button_text", "")) == "Equipped", "equipped item button should read Equipped")

	_finish()

func _equipment_payload(id: String, item_name: String, pool: String, level: int, affixes: Dictionary, rarity: String = "magic") -> Dictionary:
	return {
		"id": id,
		"name": item_name,
		"type": "equipment",
		"amount": 1,
		"equipment": {
			"instance_id": id,
			"name": item_name,
			"slot": "weapon",
			"equipment_pool": pool,
			"item_level": level,
			"rarity": rarity,
			"affixes": affixes,
		},
	}

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_EQUIPMENT_ACTION_HINT_SERVICE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
