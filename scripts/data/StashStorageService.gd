extends RefCounted
class_name StashStorageService

const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const EquipmentDataServiceScript := preload("res://scripts/data/EquipmentDataService.gd")

const DEFAULT_STASH_CAPACITY := 80

static func normalize_stash(stash: Variant) -> Dictionary:
	if stash is Dictionary:
		return Dictionary(stash).duplicate(true)
	return {}

static func get_default_capacity() -> int:
	return DEFAULT_STASH_CAPACITY

static func build_capacity_summary(stash: Dictionary, capacity: int = DEFAULT_STASH_CAPACITY) -> Dictionary:
	return InventoryDataServiceScript.build_capacity_summary(normalize_stash(stash), capacity)

static func deposit_item(player_data: Dictionary, stash: Dictionary, item_id: String, stash_capacity: int = DEFAULT_STASH_CAPACITY) -> Dictionary:
	var result_player := player_data.duplicate(true)
	var bag := InventoryDataServiceScript.normalize_inventory(result_player.get("inventory", {}))
	var result_stash := normalize_stash(stash)
	if not bag.has(item_id):
		return _failed("missing_bag_item", result_player, result_stash)
	var entry: Dictionary = Dictionary(bag[item_id]).duplicate(true)
	if EquipmentDataServiceScript.is_equipped_item(result_player, item_id):
		return _failed("equipped_item", result_player, result_stash)
	var transfer := _add_entry_to_container(result_stash, entry, stash_capacity)
	if not bool(transfer.get("ok", false)):
		return _failed(str(transfer.get("reason", "stash_full")), result_player, result_stash)
	result_stash = Dictionary(transfer.get("container", result_stash))
	bag.erase(item_id)
	result_player["inventory"] = bag
	return {
		"ok": true,
		"mode": "deposit",
		"item_id": item_id,
		"player_data": result_player,
		"stash": result_stash,
	}

static func withdraw_item(player_data: Dictionary, stash: Dictionary, item_id: String, bag_capacity: int = InventoryDataServiceScript.DEFAULT_CAPACITY) -> Dictionary:
	var result_player := player_data.duplicate(true)
	var bag := InventoryDataServiceScript.normalize_inventory(result_player.get("inventory", {}))
	var result_stash := normalize_stash(stash)
	if not result_stash.has(item_id):
		return _failed("missing_stash_item", result_player, result_stash)
	var entry: Dictionary = Dictionary(result_stash[item_id]).duplicate(true)
	var transfer := _add_entry_to_container(bag, entry, bag_capacity)
	if not bool(transfer.get("ok", false)):
		return _failed("bag_full", result_player, result_stash)
	bag = Dictionary(transfer.get("container", bag))
	result_stash.erase(item_id)
	result_player["inventory"] = bag
	return {
		"ok": true,
		"mode": "withdraw",
		"item_id": item_id,
		"player_data": result_player,
		"stash": result_stash,
	}

static func _add_entry_to_container(container: Dictionary, entry: Dictionary, capacity: int) -> Dictionary:
	var result := InventoryDataServiceScript.normalize_inventory(container)
	var item_id := str(entry.get("id", ""))
	if item_id == "":
		return {"ok": false, "reason": "missing_item_id", "container": result}
	var item_type := str(entry.get("type", "item"))
	if result.has(item_id) and item_type != "equipment":
		var target: Dictionary = Dictionary(result[item_id]).duplicate(true)
		target["amount"] = int(target.get("amount", 0)) + int(entry.get("amount", 1))
		result[item_id] = target
		return {"ok": true, "container": result}
	if result.has(item_id):
		return {"ok": false, "reason": "duplicate_item_id", "container": result}
	if InventoryDataServiceScript.get_used_slots(result) >= maxi(1, capacity):
		return {"ok": false, "reason": "container_full", "container": result}
	result[item_id] = entry.duplicate(true)
	return {"ok": true, "container": result}

static func _failed(reason: String, player_data: Dictionary, stash: Dictionary) -> Dictionary:
	return {
		"ok": false,
		"reason": reason,
		"player_data": player_data.duplicate(true),
		"stash": normalize_stash(stash),
	}
