extends RefCounted
class_name InventoryItemActionService

const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const EquipmentDataServiceScript := preload("res://scripts/data/EquipmentDataService.gd")

const SELL_GOLD_ID := "gold"
const SALVAGE_MATERIAL_ID := "crystal_shard"
const VALID_MODES := ["sell", "salvage"]

static func normalize_action_mode(mode: String) -> String:
	return mode if VALID_MODES.has(mode) else "sell"

static func build_junk_action_preview(player_data: Dictionary, mode: String = "sell") -> Dictionary:
	var action_mode := normalize_action_mode(mode)
	var inventory: Dictionary = InventoryDataServiceScript.normalize_inventory(player_data.get("inventory", {}))
	var candidate_ids: Array[String] = []
	var protected_ids: Array[String] = []
	var gold_gain := 0
	var crystal_gain := 0
	for item_id in inventory.keys():
		var id := str(item_id)
		var entry: Dictionary = Dictionary(inventory[item_id])
		if not _is_junk(entry):
			continue
		if _is_protected(player_data, id, entry):
			protected_ids.append(id)
			continue
		candidate_ids.append(id)
		if action_mode == "salvage":
			crystal_gain += _get_salvage_value(entry)
		else:
			gold_gain += _get_sell_value(entry)
	candidate_ids.sort()
	protected_ids.sort()
	var action_label := "Salvage" if action_mode == "salvage" else "Sell"
	var reward_text := "+%d Crystal" % crystal_gain if action_mode == "salvage" else "+%d Gold" % gold_gain
	return {
		"mode": action_mode,
		"can_process": candidate_ids.size() > 0,
		"candidate_item_ids": candidate_ids,
		"protected_item_ids": protected_ids,
		"processed_count": candidate_ids.size(),
		"protected_count": protected_ids.size(),
		"gold_gain": gold_gain,
		"crystal_gain": crystal_gain,
		"summary_text": "%s Junk %d (%s)" % [action_label, candidate_ids.size(), reward_text],
	}

static func process_junk_action(player_data: Dictionary, mode: String = "sell") -> Dictionary:
	var action_mode := normalize_action_mode(mode)
	var preview := build_junk_action_preview(player_data, action_mode)
	var result := player_data.duplicate(true)
	if not bool(preview.get("can_process", false)):
		return {
			"ok": false,
			"reason": "no_junk_candidates",
			"player_data": result,
			"preview": preview,
		}
	var inventory: Dictionary = InventoryDataServiceScript.normalize_inventory(result.get("inventory", {}))
	for item_id in Array(preview.get("candidate_item_ids", [])):
		inventory.erase(str(item_id))
	if action_mode == "salvage":
		var crystal_gain := int(preview.get("crystal_gain", 0))
		if crystal_gain > 0:
			inventory = InventoryDataServiceScript.add_item(inventory, {
				"id": SALVAGE_MATERIAL_ID,
				"name": "Crystal Shard",
				"type": "material",
				"amount": crystal_gain,
			})
	else:
		var gold_gain := int(preview.get("gold_gain", 0))
		if gold_gain > 0:
			inventory = InventoryDataServiceScript.add_item(inventory, {
				"id": SELL_GOLD_ID,
				"name": "Gold",
				"type": "currency",
				"amount": gold_gain,
			})
	result["inventory"] = inventory
	return {
		"ok": true,
		"mode": action_mode,
		"player_data": result,
		"preview": preview,
		"processed_item_ids": Array(preview.get("candidate_item_ids", [])),
		"protected_item_ids": Array(preview.get("protected_item_ids", [])),
		"gold_gain": int(preview.get("gold_gain", 0)),
		"crystal_gain": int(preview.get("crystal_gain", 0)),
		"summary_text": str(preview.get("summary_text", "")),
	}

static func _is_junk(entry: Dictionary) -> bool:
	var flags: Dictionary = Dictionary(entry.get("binding_flags", {}))
	return bool(flags.get("junk", entry.get("junk", false)))

static func _is_protected(player_data: Dictionary, item_id: String, entry: Dictionary) -> bool:
	var flags: Dictionary = Dictionary(entry.get("binding_flags", {}))
	if bool(flags.get("locked", entry.get("locked", false))):
		return true
	if bool(flags.get("favorite", entry.get("favorite", false))):
		return true
	if not bool(flags.get("sellable", entry.get("sellable", true))):
		return true
	return EquipmentDataServiceScript.is_equipped_item(player_data, item_id)

static func _get_sell_value(entry: Dictionary) -> int:
	if str(entry.get("type", "")) == "equipment":
		var score := EquipmentDataServiceScript.get_equipment_score(Dictionary(entry.get("equipment", {})))
		return maxi(1, 6 + int(round(float(score) * 0.45)))
	return maxi(1, int(entry.get("amount", 1)))

static func _get_salvage_value(entry: Dictionary) -> int:
	if str(entry.get("type", "")) == "equipment":
		var equipment: Dictionary = Dictionary(entry.get("equipment", {}))
		var rarity := str(equipment.get("rarity", "common"))
		var rarity_bonus := 2 if rarity == "rare" else 3 if rarity == "legendary" else 1
		return maxi(1, rarity_bonus + int(EquipmentDataServiceScript.get_equipment_score(equipment) / 25))
	return maxi(1, int(ceil(float(entry.get("amount", 1)) / 3.0)))
