extends RefCounted
class_name TownPrepRecommendationService

const EquipmentActionHintServiceScript := preload("res://scripts/data/EquipmentActionHintService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")

static func build_recommendations(player_data: Dictionary) -> Dictionary:
	var inventory: Dictionary = InventoryDataServiceScript.normalize_inventory(player_data.get("inventory", {}))
	var capacity: Dictionary = InventoryDataServiceScript.build_capacity_summary(inventory)
	var items: Array[Dictionary] = []
	var skill_points := int(player_data.get("skill_points", 0))
	if skill_points > 0:
		items.append(_make_item(
			"spend_skill_points",
			10,
			"Spend SP %d before climbing." % skill_points,
			"open_skills",
			"Open Skills"
		))
	var upgrade_count := _count_equipment_upgrades(player_data, inventory)
	if upgrade_count > 0:
		items.append(_make_item(
			"equip_upgrade",
			20,
			"Equip upgrade: %d item(s) look stronger." % upgrade_count,
			"open_equipment",
			"Open Equipment"
		))
	if bool(capacity.get("pressure", false)):
		var bag_item := _make_item(
			"manage_bag",
			30,
			"Bag pressure: %d/%d slots, sort before a long run." % [
				int(capacity.get("used_slots", 0)),
				int(capacity.get("capacity", 0)),
			],
			"open_inventory",
			"Open Bag"
		)
		bag_item["used_slots"] = int(capacity.get("used_slots", 0))
		bag_item["capacity"] = int(capacity.get("capacity", 0))
		bag_item["free_slots"] = int(capacity.get("free_slots", 0))
		bag_item["pressure_ratio"] = float(capacity.get("pressure_ratio", 0.0))
		items.append(bag_item)
	items.sort_custom(_sort_recommendations)
	if items.is_empty():
		return {
			"has_action": false,
			"items": [],
			"recommendation_text": "Ready: no urgent prep actions.",
			"primary_action_id": "",
			"primary_button_text": "",
			"primary_recommendation_id": "",
		}
	var primary := Dictionary(items[0])
	return {
		"has_action": true,
		"items": items,
		"recommendation_text": _join_recommendation_text(items),
		"primary_action_id": str(primary.get("action_id", "")),
		"primary_button_text": str(primary.get("button_text", "")),
		"primary_recommendation_id": str(primary.get("id", "")),
	}

static func _make_item(id: String, priority: int, text: String, action_id: String, button_text: String) -> Dictionary:
	return {
		"id": id,
		"priority": priority,
		"text": text,
		"action_id": action_id,
		"button_text": button_text,
	}

static func _count_equipment_upgrades(player_data: Dictionary, inventory: Dictionary) -> int:
	var count := 0
	for item_id in inventory.keys():
		var entry: Dictionary = Dictionary(inventory[item_id])
		if str(entry.get("type", "")) != "equipment":
			continue
		var hint: Dictionary = EquipmentActionHintServiceScript.build_hint(player_data, str(item_id))
		if bool(hint.get("can_equip", false)) and bool(hint.get("upgrade", false)):
			count += 1
	return count

static func _join_recommendation_text(items: Array[Dictionary]) -> String:
	var lines: Array[String] = []
	for item in items:
		lines.append(str(item.get("text", "")))
	return "\n".join(lines)

static func _sort_recommendations(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("priority", 0)) < int(b.get("priority", 0))
