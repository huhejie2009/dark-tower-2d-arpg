extends RefCounted
class_name EquipmentDataService

const GameConstantsScript := preload("res://scripts/app/GameConstants.gd")

static func normalize_equipment(equipment: Variant) -> Dictionary:
	if equipment is Dictionary:
		return Dictionary(equipment).duplicate(true)
	return {}

static func normalize_equipped_items(equipped_items: Variant) -> Dictionary:
	var source: Dictionary = {}
	if equipped_items is Dictionary:
		source = Dictionary(equipped_items)
	var result: Dictionary = {}
	for slot in GameConstantsScript.EQUIPMENT_SLOTS:
		result[slot] = str(source.get(slot, ""))
	if result.get("ring_1", "") == "" and str(source.get("ring", "")) != "":
		result["ring_1"] = str(source.get("ring", ""))
	return result

static func get_equippable_slots(equipment: Dictionary) -> Array[String]:
	var slot := str(equipment.get("slot", ""))
	if slot == "ring":
		return ["ring_1", "ring_2"]
	if GameConstantsScript.EQUIPMENT_SLOTS.has(slot):
		return [slot]
	return []

static func resolve_equip_slot(player_data: Dictionary, equipment: Dictionary, preferred_slot: String = "") -> String:
	var slots := get_equippable_slots(equipment)
	if slots.is_empty():
		return ""
	var equipped := normalize_equipped_items(player_data.get("equipped_items", {}))
	if preferred_slot != "" and slots.has(preferred_slot):
		return preferred_slot
	for slot in slots:
		if str(equipped.get(slot, "")) == "":
			return slot
	return slots[0]

static func can_equip(player_data: Dictionary, item_id: String) -> Dictionary:
	var inventory: Dictionary = Dictionary(player_data.get("inventory", {}))
	if not inventory.has(item_id):
		return {"ok": false, "reason": "missing_item"}
	var entry: Dictionary = Dictionary(inventory[item_id])
	if str(entry.get("type", "")) != "equipment":
		return {"ok": false, "reason": "not_equipment"}
	var equipment: Dictionary = Dictionary(entry.get("equipment", {}))
	var slot := resolve_equip_slot(player_data, equipment)
	if slot == "":
		return {"ok": false, "reason": "bad_slot"}
	var pool := str(equipment.get("equipment_pool", ""))
	var base_class := str(player_data.get("base_class", "warrior"))
	if pool != "" and pool != base_class:
		return {"ok": false, "reason": "wrong_class"}
	return {"ok": true, "slot": slot, "item_id": item_id}

static func equip_item(player_data: Dictionary, item_id: String, preferred_slot: String = "") -> Dictionary:
	var result: Dictionary = player_data.duplicate(true)
	result["equipped_items"] = normalize_equipped_items(result.get("equipped_items", {}))
	var check := can_equip(result, item_id)
	if bool(check.get("ok", false)) and preferred_slot != "":
		var inventory: Dictionary = Dictionary(result.get("inventory", {}))
		var equipment: Dictionary = Dictionary(Dictionary(inventory.get(item_id, {})).get("equipment", {}))
		var resolved_preferred := resolve_equip_slot(result, equipment, preferred_slot)
		if resolved_preferred == "":
			check = {"ok": false, "reason": "bad_slot", "item_id": item_id}
		else:
			check["slot"] = resolved_preferred
	if not bool(check.get("ok", false)):
		check["player_data"] = result
		return check
	var equipped: Dictionary = Dictionary(result["equipped_items"])
	var slot := str(check.get("slot", ""))
	var replaced_item_id := str(equipped.get(slot, ""))
	equipped[slot] = item_id
	result["equipped_items"] = equipped
	return {
		"ok": true,
		"slot": slot,
		"item_id": item_id,
		"replaced_item_id": replaced_item_id,
		"player_data": result,
	}

static func unequip_slot(player_data: Dictionary, slot: String) -> Dictionary:
	var result: Dictionary = player_data.duplicate(true)
	if not GameConstantsScript.EQUIPMENT_SLOTS.has(slot):
		return {"ok": false, "reason": "bad_slot", "player_data": result}
	var equipped := normalize_equipped_items(result.get("equipped_items", {}))
	equipped[slot] = ""
	result["equipped_items"] = equipped
	return {"ok": true, "slot": slot, "player_data": result}

static func build_stat_totals(player_data: Dictionary) -> Dictionary:
	var totals := {
		"attack_damage": int(player_data.get("attack_damage", 0)),
		"max_health": int(player_data.get("max_health", 0)),
		"max_mana": int(player_data.get("max_mana", 0)),
		"defense": 0,
		"critical_chance": 0,
		"projectile_count": 0,
		"summon_damage": 0,
	}
	var inventory: Dictionary = Dictionary(player_data.get("inventory", {}))
	var equipped := normalize_equipped_items(player_data.get("equipped_items", {}))
	for slot in equipped.keys():
		var item_id := str(equipped[slot])
		if not inventory.has(item_id):
			continue
		var equipment: Dictionary = Dictionary(Dictionary(inventory[item_id]).get("equipment", {}))
		var affixes: Dictionary = Dictionary(equipment.get("affixes", {}))
		for stat_id in affixes.keys():
			totals[stat_id] = int(totals.get(stat_id, 0)) + int(affixes[stat_id])
	return totals

static func get_equipment_score(equipment: Dictionary) -> int:
	var score := int(equipment.get("item_level", 1))
	var rarity := str(equipment.get("rarity", "common"))
	if rarity == "magic":
		score += 10
	elif rarity == "rare":
		score += 25
	elif rarity == "legendary":
		score += 50
	var affixes: Dictionary = Dictionary(equipment.get("affixes", {}))
	for stat_id in affixes.keys():
		var value := int(affixes[stat_id])
		if str(stat_id) == "critical_chance" or str(stat_id) == "projectile_count":
			score += value * 8
		else:
			score += value
	return score

static func get_item_score(player_data: Dictionary, item_id: String) -> int:
	var inventory: Dictionary = Dictionary(player_data.get("inventory", {}))
	if not inventory.has(item_id):
		return 0
	var entry: Dictionary = Dictionary(inventory[item_id])
	if str(entry.get("type", "")) != "equipment":
		return 0
	return get_equipment_score(Dictionary(entry.get("equipment", {})))

static func is_equipped_item(player_data: Dictionary, item_id: String) -> bool:
	if item_id == "":
		return false
	var equipped := normalize_equipped_items(player_data.get("equipped_items", {}))
	for slot in equipped.keys():
		if str(equipped[slot]) == item_id:
			return true
	return false

static func is_upgrade_candidate(player_data: Dictionary, item_id: String) -> bool:
	if is_equipped_item(player_data, item_id):
		return false
	var inventory: Dictionary = Dictionary(player_data.get("inventory", {}))
	if not inventory.has(item_id):
		return false
	var entry: Dictionary = Dictionary(inventory[item_id])
	if str(entry.get("type", "")) != "equipment":
		return false
	var equipment: Dictionary = Dictionary(entry.get("equipment", {}))
	var slot := resolve_equip_slot(player_data, equipment)
	if slot == "":
		return false
	var equipped := normalize_equipped_items(player_data.get("equipped_items", {}))
	var equipped_id := str(equipped.get(slot, ""))
	if equipped_id == "":
		return true
	if not inventory.has(equipped_id):
		return true
	return get_equipment_score(equipment) > get_item_score(player_data, equipped_id)
