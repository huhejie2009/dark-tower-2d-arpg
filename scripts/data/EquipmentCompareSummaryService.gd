extends RefCounted
class_name EquipmentCompareSummaryService

const EquipmentDataServiceScript := preload("res://scripts/data/EquipmentDataService.gd")

const RANGER_COC_REASON_TEXT := {
	"critical_chance": "更频繁触发冰矛",
	"attack_speed": "更多寒冰射击尝试，但仍受触发冷却限制",
	"cold_damage": "增强寒冰射击和冰矛",
	"ice_lance_pierce": "冰矛穿透，清理密集敌人更强",
	"ice_lance_split": "冰矛分裂，提升清图覆盖",
	"coc_cooldown_recovery": "允许更高频率触发冰矛",
}

static func build_summary(player_data: Dictionary, candidate_item_id: String, candidate_equipment: Dictionary) -> Dictionary:
	var slot := EquipmentDataServiceScript.resolve_equip_slot(player_data, candidate_equipment)
	var inventory: Dictionary = Dictionary(player_data.get("inventory", {}))
	var equipped := EquipmentDataServiceScript.normalize_equipped_items(player_data.get("equipped_items", {}))
	var equipped_item_id := str(equipped.get(slot, ""))
	var candidate_score := EquipmentDataServiceScript.get_equipment_score(candidate_equipment)
	var equipped_score := 0
	var equipped_equipment: Dictionary = {}
	if equipped_item_id != "" and inventory.has(equipped_item_id):
		equipped_equipment = Dictionary(Dictionary(inventory[equipped_item_id]).get("equipment", {}))
		equipped_score = EquipmentDataServiceScript.get_equipment_score(equipped_equipment)
	var score_delta := candidate_score - equipped_score
	var stat_deltas := _build_stat_deltas(candidate_equipment, equipped_equipment)
	var reason_lines := _build_reason_lines(score_delta, stat_deltas, equipped_item_id)
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
		"reason_lines": reason_lines,
		"primary_reason": "" if reason_lines.is_empty() else str(reason_lines[0]),
		"compact_text": _build_compact_text(score_delta, stat_deltas, equipped_item_id, reason_lines),
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
		var reason := _build_stat_reason(str(stat_id), delta)
		rows.append({
			"stat_id": str(stat_id),
			"candidate_value": candidate_value,
			"equipped_value": equipped_value,
			"delta": delta,
			"compact_text": "%s %s%d" % [str(stat_id), sign, delta],
			"reason_text": reason,
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

static func _build_reason_lines(score_delta: int, stat_deltas: Array, equipped_item_id: String) -> Array[String]:
	var reasons: Array[String] = []
	var score_sign := "+" if score_delta > 0 else ""
	if equipped_item_id == "":
		reasons.append("Score %s%d vs empty slot" % [score_sign, score_delta])
	else:
		reasons.append("Score %s%d vs equipped" % [score_sign, score_delta])
	var sorted_deltas := stat_deltas.duplicate(true)
	sorted_deltas.sort_custom(_sort_reason_rows)
	for row in sorted_deltas:
		if reasons.size() >= 4:
			break
		var data: Dictionary = Dictionary(row)
		var delta := int(data.get("delta", 0))
		if delta == 0:
			continue
		var reason := str(data.get("reason_text", ""))
		if delta > 0 and reason != "":
			reasons.append(reason)
			continue
		var sign := "+" if delta > 0 else ""
		reasons.append("%s %s%d" % [str(data.get("stat_id", "")), sign, delta])
	return reasons

static func _build_stat_reason(stat_id: String, delta: int) -> String:
	if delta <= 0:
		return ""
	return str(RANGER_COC_REASON_TEXT.get(stat_id, ""))

static func _sort_reason_rows(a: Variant, b: Variant) -> bool:
	var data_a: Dictionary = Dictionary(a)
	var data_b: Dictionary = Dictionary(b)
	var reason_a := str(data_a.get("reason_text", "")) != ""
	var reason_b := str(data_b.get("reason_text", "")) != ""
	if reason_a != reason_b:
		return reason_a
	var positive_a := int(data_a.get("delta", 0)) > 0
	var positive_b := int(data_b.get("delta", 0)) > 0
	if positive_a != positive_b:
		return positive_a
	return abs(int(data_a.get("delta", 0))) > abs(int(data_b.get("delta", 0)))

static func _build_compact_text(score_delta: int, stat_deltas: Array, equipped_item_id: String, reason_lines: Array[String] = []) -> String:
	var score_sign := "+" if score_delta > 0 else ""
	var parts: Array[String] = ["Score %s%d" % [score_sign, score_delta]]
	if equipped_item_id == "":
		parts.append("empty slot")
	if not reason_lines.is_empty():
		parts.append(str(reason_lines[0]))
	var shown := 0
	for row in stat_deltas:
		if shown >= 2:
			break
		parts.append(str(Dictionary(row).get("compact_text", "")))
		shown += 1
	return " | ".join(parts)
