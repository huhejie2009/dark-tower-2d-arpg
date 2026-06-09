extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const InventoryQueryServiceScript := preload("res://scripts/data/InventoryQueryService.gd")

var failures: Array[String] = []

func _init() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Query", "warrior")
	player["inventory"] = {}
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player["inventory"]), {"id": "gold", "name": "Gold", "type": "currency", "amount": 100})
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player["inventory"]), {"id": "crystal", "name": "Crystal", "type": "material", "amount": 3})
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player["inventory"]), _equipment_payload("weak_weapon", "Weak Sword", "weapon", 1, {"attack_damage": 2}))
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player["inventory"]), _equipment_payload("better_weapon", "Better Sword", "weapon", 8, {"attack_damage": 28}))
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player["inventory"]), _equipment_payload("locked_armor", "Locked Armor", "armor", 4, {"defense": 7}, {"locked": true}))
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player["inventory"]), _equipment_payload("favorite_gloves", "Favorite Gloves", "gloves", 3, {"critical_chance": 1}, {"favorite": true}))
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player["inventory"]), _equipment_payload("junk_armor", "Junk Armor", "armor", 1, {"defense": 1}, {"junk": true}))
	player["equipped_items"] = {"weapon": "weak_weapon", "armor": "", "gloves": "", "ring_1": "", "ring_2": ""}

	var all_ids := InventoryQueryServiceScript.query_item_ids(player, {"filter_mode": "all", "sort_mode": "type"})
	_expect(all_ids.has("gold") and all_ids.has("better_weapon"), "all filter should include materials and equipment")
	_expect(all_ids[0] == "locked_armor", "locked items should sort first")

	var material_ids := InventoryQueryServiceScript.query_item_ids(player, {"filter_mode": "material", "sort_mode": "type"})
	_expect(_same_ids(material_ids, ["crystal", "gold"]), "material filter should include material and currency")

	var equipment_ids := InventoryQueryServiceScript.query_item_ids(player, {"filter_mode": "equipment", "sort_mode": "name"})
	_expect(equipment_ids.has("better_weapon") and not equipment_ids.has("gold"), "equipment filter should only include equipment")
	_expect(equipment_ids.find("better_weapon") < equipment_ids.find("favorite_gloves"), "name sort should use display names")

	var upgrade_ids := InventoryQueryServiceScript.query_item_ids(player, {"filter_mode": "upgrade", "sort_mode": "power"})
	_expect(upgrade_ids.has("better_weapon"), "upgrade filter should include better weapon")
	_expect(not upgrade_ids.has("weak_weapon"), "upgrade filter should not include equipped weapon")

	var locked_ids := InventoryQueryServiceScript.query_item_ids(player, {"filter_mode": "locked", "sort_mode": "name"})
	_expect(_same_ids(locked_ids, ["locked_armor"]), "locked filter should use binding flags")
	var favorite_ids := InventoryQueryServiceScript.query_item_ids(player, {"filter_mode": "favorite", "sort_mode": "name"})
	_expect(_same_ids(favorite_ids, ["favorite_gloves"]), "favorite filter should use binding flags")
	var junk_ids := InventoryQueryServiceScript.query_item_ids(player, {"filter_mode": "junk", "sort_mode": "name"})
	_expect(_same_ids(junk_ids, ["junk_armor"]), "junk filter should use binding flags")

	var power_ids := InventoryQueryServiceScript.query_item_ids(player, {"filter_mode": "equipment", "sort_mode": "power"})
	_expect(power_ids.find("better_weapon") < power_ids.find("weak_weapon"), "power sort should put stronger gear first")
	_finish()

func _equipment_payload(id: String, item_name: String, slot: String, level: int, affixes: Dictionary, flags: Dictionary = {}) -> Dictionary:
	return {
		"id": id,
		"name": item_name,
		"type": "equipment",
		"binding_flags": flags,
		"equipment": {
			"instance_id": id,
			"name": item_name,
			"slot": slot,
			"equipment_pool": "warrior",
			"item_level": level,
			"rarity": "magic",
			"affixes": affixes,
		},
	}

func _same_ids(actual: Array, expected: Array) -> bool:
	var actual_sorted := actual.duplicate()
	var expected_sorted := expected.duplicate()
	actual_sorted.sort()
	expected_sorted.sort()
	if actual_sorted.size() != expected_sorted.size():
		return false
	for i in range(actual_sorted.size()):
		if str(actual_sorted[i]) != str(expected_sorted[i]):
			return false
	return true

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_INVENTORY_QUERY_SERVICE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

