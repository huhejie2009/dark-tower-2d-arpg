extends RefCounted
class_name VendorTransactionService

const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const EquipmentDataServiceScript := preload("res://scripts/data/EquipmentDataService.gd")

const GOLD_ID := "gold"
const BUYBACK_PRICE_MULTIPLIER := 1
const MAX_BUYBACK_ENTRIES := 12

static func sell_item(player_data: Dictionary, buyback: Array, item_id: String) -> Dictionary:
	var result_player := player_data.duplicate(true)
	var inventory := InventoryDataServiceScript.normalize_inventory(result_player.get("inventory", {}))
	var result_buyback := normalize_buyback(buyback)
	if not inventory.has(item_id):
		return _failed("missing_item", result_player, result_buyback)
	var entry: Dictionary = Dictionary(inventory[item_id]).duplicate(true)
	if _is_protected(result_player, item_id, entry):
		return _failed("protected_item", result_player, result_buyback)
	var sell_value := get_sell_value(entry)
	inventory.erase(item_id)
	if sell_value > 0:
		inventory = InventoryDataServiceScript.add_item(inventory, {
			"id": GOLD_ID,
			"name": "Gold",
			"type": "currency",
			"amount": sell_value,
		})
	result_buyback.push_front({
		"item_id": item_id,
		"entry": entry,
		"sell_value": sell_value,
		"buyback_price": get_buyback_price(entry),
	})
	while result_buyback.size() > MAX_BUYBACK_ENTRIES:
		result_buyback.pop_back()
	result_player["inventory"] = inventory
	return {
		"ok": true,
		"mode": "sell",
		"item_id": item_id,
		"sell_value": sell_value,
		"player_data": result_player,
		"buyback": result_buyback,
	}

static func buyback_item(player_data: Dictionary, buyback: Array, item_id: String) -> Dictionary:
	var result_player := player_data.duplicate(true)
	var inventory := InventoryDataServiceScript.normalize_inventory(result_player.get("inventory", {}))
	var result_buyback := normalize_buyback(buyback)
	var index := _find_buyback_index(result_buyback, item_id)
	if index < 0:
		return _failed("missing_buyback_item", result_player, result_buyback)
	var buyback_entry: Dictionary = Dictionary(result_buyback[index])
	var entry: Dictionary = Dictionary(buyback_entry.get("entry", {})).duplicate(true)
	var price := int(buyback_entry.get("buyback_price", get_buyback_price(entry)))
	if _get_gold_amount(inventory) < price:
		return _failed("not_enough_gold", result_player, result_buyback)
	var add_result := _add_entry_to_bag(inventory, entry)
	if not bool(add_result.get("ok", false)):
		return _failed(str(add_result.get("reason", "bag_full")), result_player, result_buyback)
	inventory = Dictionary(add_result.get("inventory", inventory))
	inventory = _spend_gold(inventory, price)
	result_buyback.remove_at(index)
	result_player["inventory"] = inventory
	return {
		"ok": true,
		"mode": "buyback",
		"item_id": item_id,
		"buyback_price": price,
		"player_data": result_player,
		"buyback": result_buyback,
	}

static func normalize_buyback(buyback: Variant) -> Array:
	var result: Array = []
	if not (buyback is Array):
		return result
	for entry in Array(buyback):
		if entry is Dictionary:
			result.append(Dictionary(entry).duplicate(true))
	return result

static func get_sell_value(entry: Dictionary) -> int:
	if str(entry.get("type", "")) == "equipment":
		return maxi(1, 6 + int(round(float(EquipmentDataServiceScript.get_equipment_score(Dictionary(entry.get("equipment", {})))) * 0.45)))
	return maxi(1, int(entry.get("amount", 1)))

static func get_buyback_price(entry: Dictionary) -> int:
	return maxi(1, get_sell_value(entry) * BUYBACK_PRICE_MULTIPLIER)

static func _is_protected(player_data: Dictionary, item_id: String, entry: Dictionary) -> bool:
	var flags: Dictionary = Dictionary(entry.get("binding_flags", {}))
	if bool(flags.get("locked", entry.get("locked", false))):
		return true
	if bool(flags.get("favorite", entry.get("favorite", false))):
		return true
	if not bool(flags.get("sellable", entry.get("sellable", true))):
		return true
	return EquipmentDataServiceScript.is_equipped_item(player_data, item_id)

static func _add_entry_to_bag(inventory: Dictionary, entry: Dictionary) -> Dictionary:
	var result := InventoryDataServiceScript.normalize_inventory(inventory)
	var item_id := str(entry.get("id", ""))
	if item_id == "":
		return {"ok": false, "reason": "missing_item_id", "inventory": result}
	var item_type := str(entry.get("type", "item"))
	if result.has(item_id) and item_type != "equipment":
		var target: Dictionary = Dictionary(result[item_id]).duplicate(true)
		target["amount"] = int(target.get("amount", 0)) + int(entry.get("amount", 1))
		result[item_id] = target
		return {"ok": true, "inventory": result}
	if result.has(item_id):
		return {"ok": false, "reason": "duplicate_item_id", "inventory": result}
	if InventoryDataServiceScript.get_used_slots(result) >= InventoryDataServiceScript.get_default_capacity():
		return {"ok": false, "reason": "bag_full", "inventory": result}
	result[item_id] = entry.duplicate(true)
	return {"ok": true, "inventory": result}

static func _find_buyback_index(buyback: Array, item_id: String) -> int:
	for index in range(buyback.size()):
		var entry: Dictionary = Dictionary(buyback[index])
		if str(entry.get("item_id", "")) == item_id:
			return index
	return -1

static func _get_gold_amount(inventory: Dictionary) -> int:
	return int(Dictionary(inventory.get(GOLD_ID, {})).get("amount", 0))

static func _spend_gold(inventory: Dictionary, amount: int) -> Dictionary:
	var result := InventoryDataServiceScript.normalize_inventory(inventory)
	var gold_entry: Dictionary = Dictionary(result.get(GOLD_ID, {
		"id": GOLD_ID,
		"name": "Gold",
		"type": "currency",
		"amount": 0,
	}))
	gold_entry["amount"] = maxi(0, int(gold_entry.get("amount", 0)) - maxi(0, amount))
	result[GOLD_ID] = gold_entry
	return result

static func _failed(reason: String, player_data: Dictionary, buyback: Array) -> Dictionary:
	return {
		"ok": false,
		"reason": reason,
		"player_data": player_data.duplicate(true),
		"buyback": normalize_buyback(buyback),
	}
