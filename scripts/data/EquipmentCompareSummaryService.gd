extends RefCounted
class_name EquipmentCompareSummaryService

const EquipmentDataServiceScript := preload("res://scripts/data/EquipmentDataService.gd")

static func build_summary(player_data: Dictionary, candidate_item_id: String, candidate_equipment: Dictionary) -> Dictionary:
	var slot := str(candidate_equipment.get("slot", ""))
	var inventory: Dictionary = Dictionary(player_data.get("inventory", {}))
	var equipped: Dictionary = Dictionary(player_data.get("equipped_items", {}))
	var equipped_item_id := str(equipped.get(slot, ""))
	var candidate_score := EquipmentDataServiceScript.get_equipment_score(candidate_equipment)
	var equipped_score := 0
	var equipped_equipment: Dictionary = {}
	if equipped_item_id != "" and inventory.has(equipped_item_id):
		equipped_equipment = Dictionary(Dictionary(inventory[equipped_item_id]).get("equipment", {}))
		equipped_score = EquipmentDataServiceScript.get_equipment_score(equipped_equipment)
	var score_delta := candidate_score - equipped_score
	var stat_deltas := _build_stat_deltas(candidate_equipment, equipped_equipment)
	var headline := _build_headline(score_delta, equipped_item_id)
	return {
		"slot": slot,
		"candidate_item_id": candidate_item_id,
		"equipped_item_id": equipped_item_id,
		"candidate_score": candidate_score,
		"equipped_score": equipped_score,
		"score_delta": score_delta,
		"headline": headline,
		"stat_deltas": stat_deltas,
		"compact_text": _build_compact_text(score_delta, stat_deltas, equipped_item_id),
		"empty_slot": equipped_item_id == "" or equipped_equipment.is_empty(),
	}

static func _build_stat_deltas(candidate_equipment: Dictionary, equipped_equipment: Dictionary) -> Array:
	var candidate_affixes: Dictionary = Dictionary(candidate_equipment.get("affixes", {}))
	var equipped_affixes: Dictionary = Dictionary(equipped_equipment.get("affixes", {}))
	var stat_ids: Array = candidate_affixes.keys()
	for stat_id in equipped_affixes.keys():
		if not stat_ids.has(stat_id):
			stat_ids.append(stat_id)
	stat_ids.sort()
	var rows: Array = []
	for stat_id in stat_ids:
		var candidate_value := int(candidate_affixes.get(stat_id, 0))
		var equipped_value := int(equipped_affixes.get(stat_id, 0))
		var delta := candidate_value - equipped_value
		if delta == 0:
			continue
		var sign := "+" if delta > 0 else ""
		rows.append({
			"stat_id": str(stat_id),
			"candidate_value": candidate_value,
			"equipped_value": equipped_value,
			"delta": delta,
			"compact_text": "%s %s%d" % [str(stat_id), sign, delta],
			"positive": delta > 0,
		})
	return rows

static func _build_headline(score_delta: int, equipped_item_id: String) -> String:
	if equipped_item_id == "":
		return "Empty slot upgrade"
	if score_delta > 0:
		return "Upgrade candidate"
	if score_delta < 0:
		return "Lower score"
	return "Sidegrade"

static func _build_compact_text(score_delta: int, stat_deltas: Array, equipped_item_id: String) -> String:
	var score_sign := "+" if score_delta > 0 else ""
	var parts: Array[String] = ["Score %s%d" % [score_sign, score_delta]]
	if equipped_item_id == "":
		parts.append("empty slot")
	var shown := 0
	for row in stat_deltas:
		if shown >= 2:
			break
		parts.append(str(Dictionary(row).get("compact_text", "")))
		shown += 1
	return " | ".join(parts)
