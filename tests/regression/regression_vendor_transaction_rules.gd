extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const VendorTransactionServiceScript := preload("res://scripts/data/VendorTransactionService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Vendor", "warrior")
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player.get("inventory", {})), _equipment_payload("sale_sword", 6))
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player.get("inventory", {})), _equipment_payload("locked_sword", 4, {"locked": true}))
	var buyback: Array = []

	var sell_result := VendorTransactionServiceScript.sell_item(player, buyback, "sale_sword")
	_expect(bool(sell_result.get("ok", false)), "selling unprotected unequipped item should succeed")
	var after_sale: Dictionary = Dictionary(sell_result.get("player_data", {}))
	var after_buyback: Array = Array(sell_result.get("buyback", []))
	_expect(not Dictionary(after_sale.get("inventory", {})).has("sale_sword"), "sold item should leave inventory")
	_expect(Dictionary(after_sale.get("inventory", {})).has("gold"), "selling should add gold")
	_expect(after_buyback.size() == 1, "selling should add item to buyback")
	_expect(str(Dictionary(after_buyback[0]).get("item_id", "")) == "sale_sword", "buyback entry should preserve item id")

	var locked_result := VendorTransactionServiceScript.sell_item(player, buyback, "locked_sword")
	_expect(not bool(locked_result.get("ok", true)), "locked item should not sell")
	_expect(str(locked_result.get("reason", "")) == "protected_item", "locked item sell should explain protection")

	var starter_weapon_id := str(Dictionary(player.get("equipped_items", {})).get("weapon", ""))
	var equipped_result := VendorTransactionServiceScript.sell_item(player, buyback, starter_weapon_id)
	_expect(not bool(equipped_result.get("ok", true)), "equipped item should not sell")
	_expect(str(equipped_result.get("reason", "")) == "protected_item", "equipped item sell should explain protection")

	var buyback_result := VendorTransactionServiceScript.buyback_item(after_sale, after_buyback, "sale_sword")
	_expect(bool(buyback_result.get("ok", false)), "buyback should restore sold item when player can afford it")
	var after_buyback_player: Dictionary = Dictionary(buyback_result.get("player_data", {}))
	_expect(Dictionary(after_buyback_player.get("inventory", {})).has("sale_sword"), "buyback should return original item to inventory")
	_expect(Array(buyback_result.get("buyback", [])).is_empty(), "buyback entry should be consumed")

	var poor_player := after_sale.duplicate(true)
	poor_player["inventory"] = InventoryDataServiceScript.add_item({}, {"id": "gold", "name": "Gold", "type": "currency", "amount": 0})
	var poor_result := VendorTransactionServiceScript.buyback_item(poor_player, after_buyback, "sale_sword")
	_expect(not bool(poor_result.get("ok", true)), "buyback should fail without enough gold")
	_expect(str(poor_result.get("reason", "")) == "not_enough_gold", "poor buyback should explain gold shortage")
	_finish()

func _equipment_payload(id: String, level: int, flags: Dictionary = {}) -> Dictionary:
	return {
		"id": id,
		"name": id,
		"type": "equipment",
		"binding_flags": flags,
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

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_VENDOR_TRANSACTION_RULES_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
