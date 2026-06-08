extends RefCounted
class_name TownPrepRecommendationService

const EquipmentActionHintServiceScript := preload("res://scripts/data/EquipmentActionHintService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")

const BAG_PRESSURE_THRESHOLD := 24

static func build_recommendations(player_data: Dictionary) -> Dictionary:
	var inventory: Dictionary = InventoryDataServiceScript.normalize_inventory(player_data.get("inventory", {}))
	var items: Array[Dictionary] = []
	var skill_points := int(player_data.get("skill_points", 0))
	if skill_points > 0:
		items.append({
			"id": "spend_skill_points",
			"priority": 10,
			"text": "Spend SP %d before climbing." % skill_points,
		})
	var upgrade_count := _count_equipment_upgrades(player_data, inventory)
	if upgrade_count > 0:
		items.append({
			"id": "equip_upgrade",
			"priority": 20,
			"text": "Equip upgrade: %d item(s) look stronger." % upgrade_count,
		})
	var inventory_items := InventoryDataServiceScript.get_total_items(inventory)
	if inventory_items >= BAG_PRESSURE_THRESHOLD:
		items.append({
			"id": "manage_bag",
			"priority": 30,
			"text": "Bag pressure: %d item(s), sort before a long run." % inventory_items,
		})
	items.sort_custom(_sort_recommendations)
	if items.is_empty():
		return {
			"has_action": false,
			"items": [],
			"recommendation_text": "Ready: no urgent prep actions.",
		}
	return {
		"has_action": true,
		"items": items,
		"recommendation_text": _join_recommendation_text(items),
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
