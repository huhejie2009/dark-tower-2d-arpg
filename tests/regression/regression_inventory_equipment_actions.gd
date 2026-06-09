extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const EquipmentDataServiceScript := preload("res://scripts/data/EquipmentDataService.gd")

var failures: Array[String] = []

func _init() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Equip Safety", "warrior")
	var starter_weapon_id := str(Dictionary(player.get("equipped_items", {})).get("weapon", ""))
	var before_ids := _inventory_ids(player)
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player["inventory"]), _weapon_payload("better_weapon", 8))
	var with_candidate_ids := _inventory_ids(player)

	var equip_result := EquipmentDataServiceScript.equip_item(player, "better_weapon")
	_expect(bool(equip_result.get("ok", false)), "weapon replacement should succeed")
	_expect(str(equip_result.get("replaced_item_id", "")) == starter_weapon_id, "equip result should report replaced weapon")
	var after: Dictionary = Dictionary(equip_result.get("player_data", {}))
	var after_equipped: Dictionary = Dictionary(after.get("equipped_items", {}))
	_expect(str(after_equipped.get("weapon", "")) == "better_weapon", "better weapon should become equipped")
	_expect(Dictionary(after.get("inventory", {})).has(starter_weapon_id), "replaced weapon should remain in inventory")
	_expect(_same_ids(with_candidate_ids, _inventory_ids(after)), "equip replacement should not add or remove inventory entries")

	var missing_result := EquipmentDataServiceScript.equip_item(after, "missing_weapon")
	_expect(not bool(missing_result.get("ok", true)), "missing item equip should fail")
	_expect(_same_ids(_inventory_ids(after), _inventory_ids(Dictionary(missing_result.get("player_data", {})))), "failed equip should not mutate inventory")
	_expect(Dictionary(Dictionary(missing_result.get("player_data", {})).get("equipped_items", {})) == after_equipped, "failed equip should not mutate equipped slots")
	_expect(_same_ids(before_ids, _without_id(with_candidate_ids, "better_weapon")), "test fixture should compare stable inventory ids")
	_finish()

func _weapon_payload(id: String, level: int) -> Dictionary:
	return {
		"id": id,
		"name": id,
		"type": "equipment",
		"equipment": {
			"instance_id": id,
			"name": id,
			"slot": "weapon",
			"equipment_pool": "warrior",
			"item_level": level,
			"rarity": "rare",
			"affixes": {"attack_damage": level},
		},
	}

func _inventory_ids(player_data: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	var inventory: Dictionary = Dictionary(player_data.get("inventory", {}))
	for item_id in inventory.keys():
		ids.append(str(item_id))
	ids.sort()
	return ids

func _without_id(ids: Array[String], id: String) -> Array[String]:
	var result: Array[String] = []
	for item_id in ids:
		if item_id != id:
			result.append(item_id)
	result.sort()
	return result

func _same_ids(a: Array[String], b: Array[String]) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if a[i] != b[i]:
			return false
	return true

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_INVENTORY_EQUIPMENT_ACTIONS_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

