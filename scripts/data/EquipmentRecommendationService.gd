extends RefCounted
class_name EquipmentRecommendationService

const EquipmentDataServiceScript := preload("res://scripts/data/EquipmentDataService.gd")

static func build_recommendation(player_data: Dictionary, equipment: Dictionary, loot_quality: Dictionary = {}) -> Dictionary:
	var item_id := str(equipment.get("instance_id", "candidate"))
	var candidate_data := player_data.duplicate(true)
	var inventory: Dictionary = Dictionary(candidate_data.get("inventory", {})).duplicate(true)
	inventory[item_id] = {
		"id": item_id,
		"name": str(equipment.get("name", item_id)),
		"type": "equipment",
		"amount": 1,
		"equipment": equipment.duplicate(true),
	}
	candidate_data["inventory"] = inventory
	var can_equip := EquipmentDataServiceScript.can_equip(candidate_data, item_id)
	var score := EquipmentDataServiceScript.get_equipment_score(equipment)
	var equipped_score := _get_equipped_slot_score(candidate_data, str(can_equip.get("slot", "")))
	var score_delta := score - equipped_score
	var upgrade := bool(can_equip.get("ok", false)) and score_delta > 0
	var source := str(loot_quality.get("source", "normal"))
	return {
		"score": score,
		"equipped_score": equipped_score,
		"score_delta": score_delta,
		"upgrade": upgrade,
		"recommendation_rank": _build_rank(score_delta, upgrade),
		"recommendation_text": _build_recommendation_text(score_delta, upgrade),
		"source": source,
		"source_label": _source_label(source),
		"quality_tag": str(loot_quality.get("quality_tag", "")),
		"equip_reason": "ok" if bool(can_equip.get("ok", false)) else str(can_equip.get("reason", "blocked")),
	}

static func _get_equipped_slot_score(player_data: Dictionary, slot: String) -> int:
	if slot == "":
		return 0
	var equipped := EquipmentDataServiceScript.normalize_equipped_items(player_data.get("equipped_items", {}))
	var equipped_id := str(equipped.get(slot, ""))
	if equipped_id == "":
		return 0
	return EquipmentDataServiceScript.get_item_score(player_data, equipped_id)

static func _build_rank(score_delta: int, upgrade: bool) -> String:
	if not upgrade:
		return "none"
	if score_delta >= 40:
		return "major"
	if score_delta >= 16:
		return "strong"
	return "minor"

static func _build_recommendation_text(score_delta: int, upgrade: bool) -> String:
	if upgrade:
		return "+%d upgrade" % score_delta
	if score_delta < 0:
		return "%d below equipped" % score_delta
	return "sidegrade"

static func _source_label(source: String) -> String:
	match source:
		"boss":
			return "Boss reward"
		"elite":
			return "Elite drop"
		_:
			return "Drop"
