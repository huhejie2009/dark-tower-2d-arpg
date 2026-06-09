extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const InventoryItemActionServiceScript := preload("res://scripts/data/InventoryItemActionService.gd")
const InventoryEquipmentWindowScript := preload("res://scripts/ui/InventoryEquipmentWindow.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Junk Actions", "warrior")
	var starter_weapon_id := str(Dictionary(player.get("equipped_items", {})).get("weapon", ""))
	var inventory: Dictionary = Dictionary(player.get("inventory", {}))
	inventory = InventoryDataServiceScript.add_item(inventory, {"id": "gold", "name": "Gold", "type": "currency", "amount": 12})
	inventory = InventoryDataServiceScript.add_item(inventory, {"id": "crystal_shard", "name": "Crystal Shard", "type": "material", "amount": 2})
	inventory = InventoryDataServiceScript.add_item(inventory, _equipment_payload("junk_sword", "Junk Sword", "weapon", 2, {"attack_damage": 3}, {"junk": true}))
	inventory = InventoryDataServiceScript.add_item(inventory, _equipment_payload("junk_armor", "Junk Armor", "armor", 3, {"defense": 2}, {"junk": true}))
	inventory = InventoryDataServiceScript.add_item(inventory, _equipment_payload("locked_junk", "Locked Junk", "armor", 1, {"defense": 1}, {"junk": true, "locked": true}))
	inventory = InventoryDataServiceScript.add_item(inventory, _equipment_payload("favorite_junk", "Favorite Junk", "ring", 1, {"critical_chance": 1}, {"junk": true, "favorite": true}))
	player["inventory"] = inventory

	var service := InventoryItemActionServiceScript.new()
	_expect(service.has_method("build_junk_action_preview"), "junk action service should expose preview")
	_expect(service.has_method("process_junk_action"), "junk action service should expose processing")

	var preview: Dictionary = Dictionary(service.call("build_junk_action_preview", player, "sell"))
	_expect(bool(preview.get("can_process", false)), "sell preview should allow processing unprotected junk")
	_expect(_same_ids(Array(preview.get("candidate_item_ids", [])), ["junk_armor", "junk_sword"]), "preview should include only unlocked non-favorite junk")
	_expect(Array(preview.get("protected_item_ids", [])).has("locked_junk"), "preview should protect locked junk")
	_expect(Array(preview.get("protected_item_ids", [])).has("favorite_junk"), "preview should protect favorite junk")
	_expect(not Array(preview.get("candidate_item_ids", [])).has(starter_weapon_id), "equipped starter weapon should never be processed")
	_expect(int(preview.get("gold_gain", 0)) > 0, "sell preview should show gold gain")
	_expect(str(preview.get("summary_text", "")).contains("Sell"), "sell preview should produce UI summary text")

	var sell_result: Dictionary = Dictionary(service.call("process_junk_action", player, "sell"))
	_expect(bool(sell_result.get("ok", false)), "sell action should succeed when junk candidates exist")
	var sold_data: Dictionary = Dictionary(sell_result.get("player_data", {}))
	var sold_inventory: Dictionary = Dictionary(sold_data.get("inventory", {}))
	_expect(not sold_inventory.has("junk_sword"), "selling junk should remove junk sword")
	_expect(not sold_inventory.has("junk_armor"), "selling junk should remove junk armor")
	_expect(sold_inventory.has("locked_junk"), "selling junk should keep locked junk")
	_expect(sold_inventory.has("favorite_junk"), "selling junk should keep favorite junk")
	_expect(int(Dictionary(sold_inventory.get("gold", {})).get("amount", 0)) > 12, "selling junk should add gold into inventory stack")

	var salvage_result: Dictionary = Dictionary(service.call("process_junk_action", player, "salvage"))
	_expect(bool(salvage_result.get("ok", false)), "salvage action should succeed when junk candidates exist")
	var salvaged_inventory: Dictionary = Dictionary(Dictionary(salvage_result.get("player_data", {})).get("inventory", {}))
	_expect(not salvaged_inventory.has("junk_sword"), "salvaging junk should remove junk sword")
	_expect(int(Dictionary(salvaged_inventory.get("crystal_shard", {})).get("amount", 0)) > 2, "salvaging junk should add crystal shards")

	var window := InventoryEquipmentWindowScript.new()
	root.add_child(window)
	window.set_player_data(player)
	await process_frame
	_expect(window.find_child("SellJunkButton", true, false) != null, "inventory window should expose sell junk action")
	_expect(window.find_child("SalvageJunkButton", true, false) != null, "inventory window should expose salvage junk action")
	_expect(window.has_method("sell_junk_items"), "inventory window should expose sell_junk_items")
	_expect(window.has_method("salvage_junk_items"), "inventory window should expose salvage_junk_items")
	if window.has_method("sell_junk_items"):
		window.call("sell_junk_items")
		var updated: Dictionary = Dictionary(window.get("player_data"))
		var updated_inventory: Dictionary = Dictionary(updated.get("inventory", {}))
		_expect(not updated_inventory.has("junk_sword"), "window sell junk should apply service result")
		_expect(updated_inventory.has("locked_junk"), "window sell junk should keep locked junk")
	window.queue_free()
	await process_frame

	_finish()

func _equipment_payload(id: String, item_name: String, slot: String, level: int, affixes: Dictionary, flags: Dictionary) -> Dictionary:
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
		print("NEW_PROJECT_INVENTORY_JUNK_BATCH_ACTIONS_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
