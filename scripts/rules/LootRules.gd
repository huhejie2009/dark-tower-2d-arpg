extends RefCounted
class_name LootRules

const EquipmentAffixRulesScript := preload("res://scripts/rules/EquipmentAffixRules.gd")
const LootQualityServiceScript := preload("res://scripts/data/LootQualityService.gd")

static func generate_enemy_drop(floor: int, base_class: String, kill_index: int) -> Dictionary:
	return generate_enemy_drop_with_source(floor, base_class, kill_index, "normal")

static func generate_enemy_drop_with_source(floor: int, base_class: String, kill_index: int, source: String = "normal") -> Dictionary:
	var quality := LootQualityServiceScript.build_quality_profile(floor, source, kill_index)
	var drop_kind := LootQualityServiceScript.choose_drop_kind(quality, kill_index)
	match drop_kind:
		"equipment":
			var equipment := _build_quality_equipment(floor, base_class, kill_index, quality)
			return _wrap_drop_payload({
				"id": str(equipment.get("instance_id", "")),
				"name": str(equipment.get("name", "Equipment")),
				"type": "equipment",
				"amount": 1,
				"equipment": equipment,
			}, quality)
		"material":
			return _wrap_drop_payload({"id": "crystal_shard", "name": "Crystal Shard", "type": "material", "amount": 1 + int(maxi(1, floor) / 6)}, quality)
		_:
			return _wrap_drop_payload({"id": "gold", "name": "Gold", "type": "currency", "amount": 8 + maxi(1, floor) * 2 + int(quality.get("item_level", floor))}, quality)

static func generate_boss_clear_reward(floor: int, base_class: String) -> Dictionary:
	var quality := LootQualityServiceScript.build_quality_profile(floor, "boss", 1)
	var equipment := EquipmentAffixRulesScript.build_boss_clear_reward(floor, base_class)
	_apply_quality_to_equipment(equipment, quality, 17)
	return _wrap_drop_payload({
		"id": str(equipment.get("instance_id", "")),
		"name": str(equipment.get("name", "Boss Reward")),
		"type": "equipment",
		"amount": 1,
		"equipment": equipment,
	}, quality)

static func sample_floor_loot_quality_for_test(floor: int, base_class: String, kills: int, source: String = "normal") -> Dictionary:
	var equipment_count := 0
	var rare_or_better_count := 0
	var highest_item_level := 0
	for kill in range(1, maxi(1, kills) + 1):
		var payload := generate_enemy_drop_with_source(floor, base_class, kill, source)
		var quality: Dictionary = Dictionary(payload.get("loot_quality", {}))
		highest_item_level = maxi(highest_item_level, int(quality.get("item_level", 0)))
		if str(payload.get("type", "")) == "equipment":
			equipment_count += 1
			var rarity := str(Dictionary(payload.get("equipment", {})).get("rarity", "common"))
			if ["rare", "legendary"].has(rarity):
				rare_or_better_count += 1
	return {
		"floor": maxi(1, floor),
		"source": source,
		"kills": maxi(1, kills),
		"equipment_count": equipment_count,
		"rare_or_better_count": rare_or_better_count,
		"highest_item_level": highest_item_level,
	}

static func _build_quality_equipment(floor: int, base_class: String, kill_index: int, quality: Dictionary) -> Dictionary:
	var equipment := EquipmentAffixRulesScript.build_floor_drop(floor, base_class, kill_index)
	_apply_quality_to_equipment(equipment, quality, kill_index)
	return equipment

static func _apply_quality_to_equipment(equipment: Dictionary, quality: Dictionary, salt: int) -> void:
	var item_level := int(quality.get("item_level", equipment.get("item_level", 1)))
	equipment["item_level"] = item_level
	equipment["rarity"] = LootQualityServiceScript.choose_rarity(quality, salt)
	equipment["loot_quality_tag"] = str(quality.get("quality_tag", ""))
	var affixes: Dictionary = Dictionary(equipment.get("affixes", {})).duplicate(true)
	var bonus := maxi(0, item_level - int(equipment.get("item_level", item_level)))
	for key in affixes.keys():
		if affixes[key] is int:
			affixes[key] = int(affixes[key]) + bonus
	equipment["affixes"] = affixes

static func _wrap_drop_payload(payload: Dictionary, quality: Dictionary) -> Dictionary:
	var result := payload.duplicate(true)
	result["source"] = str(quality.get("source", "normal"))
	result["loot_quality"] = quality.duplicate(true)
	return result
