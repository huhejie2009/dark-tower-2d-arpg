extends SceneTree

const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")
const SaveSchemaScript := preload("res://scripts/save/SaveSchema.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const VendorTransactionServiceScript := preload("res://scripts/data/VendorTransactionService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := SaveManagerScript.create_character("slot_1", "Buyback Save", "warrior")
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player.get("inventory", {})), _equipment_payload("buyback_sword"))
	SaveManagerScript.save_active_player_data(player, 1)
	SaveManagerScript.save_active_vendor_buyback([])

	var sell_result := VendorTransactionServiceScript.sell_item(player, SaveManagerScript.get_active_vendor_buyback(), "buyback_sword")
	_expect(bool(sell_result.get("ok", false)), "fixture item should sell")
	var sold_player: Dictionary = Dictionary(sell_result.get("player_data", {}))
	SaveManagerScript.save_active_player_data(sold_player, 1)
	SaveManagerScript.save_active_vendor_buyback(Array(sell_result.get("buyback", [])))

	var loaded_buyback := SaveManagerScript.get_active_vendor_buyback()
	_expect(loaded_buyback.size() == 1, "saved buyback should reload")
	_expect(str(Dictionary(loaded_buyback[0]).get("item_id", "")) == "buyback_sword", "buyback item id should persist")
	_expect(Dictionary(Dictionary(loaded_buyback[0]).get("entry", {})).has("equipment"), "buyback entry should keep original item data")

	var buyback_result := VendorTransactionServiceScript.buyback_item(SaveManagerScript.get_active_player_data(), loaded_buyback, "buyback_sword")
	_expect(bool(buyback_result.get("ok", false)), "saved buyback should be usable after reload")
	SaveManagerScript.save_active_player_data(Dictionary(buyback_result.get("player_data", {})), 1)
	SaveManagerScript.save_active_vendor_buyback(Array(buyback_result.get("buyback", [])))
	_expect(SaveManagerScript.get_active_vendor_buyback().is_empty(), "buyback should be empty after restoring item")

	var legacy_slot := SaveSchemaScript.empty_slot("slot_1")
	legacy_slot["exists"] = true
	legacy_slot["player"] = player
	legacy_slot.erase("vendor_buyback")
	var normalized := SaveSchemaScript.normalize_slot("slot_1", legacy_slot)
	_expect(normalized.get("vendor_buyback", null) is Array, "legacy slots should normalize vendor_buyback as array")
	_expect(Array(normalized.get("vendor_buyback", [])).is_empty(), "legacy vendor_buyback should default empty")
	_finish()

func _equipment_payload(id: String) -> Dictionary:
	return {
		"id": id,
		"name": id,
		"type": "equipment",
		"equipment": {
			"instance_id": id,
			"name": id,
			"slot": "weapon",
			"equipment_pool": "warrior",
			"item_level": 5,
			"rarity": "rare",
			"affixes": {"attack_damage": 5},
		},
	}

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_VENDOR_BUYBACK_SAVE_BRIDGE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
