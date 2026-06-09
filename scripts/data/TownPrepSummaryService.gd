extends RefCounted
class_name TownPrepSummaryService

const ClassRulesScript := preload("res://scripts/rules/ClassRules.gd")
const EquipmentDataServiceScript := preload("res://scripts/data/EquipmentDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const TowerRunStartServiceScript := preload("res://scripts/data/TowerRunStartService.gd")
const TownPrepRecommendationServiceScript := preload("res://scripts/data/TownPrepRecommendationService.gd")
const GameConstantsScript := preload("res://scripts/app/GameConstants.gd")

static func build_summary(player_data: Dictionary) -> Dictionary:
	var inventory: Dictionary = InventoryDataServiceScript.normalize_inventory(player_data.get("inventory", {}))
	var stats: Dictionary = EquipmentDataServiceScript.build_stat_totals(player_data)
	var start_options: Dictionary = TowerRunStartServiceScript.build_start_options(player_data)
	var recommendations: Dictionary = TownPrepRecommendationServiceScript.build_recommendations(player_data)
	var inventory_capacity: Dictionary = InventoryDataServiceScript.build_capacity_summary(inventory)
	var gear_score := _get_total_equipment_score(player_data)
	var gold := _get_inventory_amount(inventory, "gold")
	var crystal := _get_inventory_amount(inventory, "crystal_shard")
	var character_text := "%s | %s | Lv.%d" % [
		str(player_data.get("character_name", "Hero")),
		ClassRulesScript.get_class_name(str(player_data.get("base_class", "warrior"))),
		int(player_data.get("player_level", 1)),
	]
	var progress_text := "Best Floor %d | Gear Score %d" % [
		int(player_data.get("highest_floor", 1)),
		gear_score,
	]
	var resource_text := "Gold %d | Crystal %d | %s" % [
		gold,
		crystal,
		str(inventory_capacity.get("summary_text", "Bag 0/40")),
	]
	var growth_text := "SP %d | Damage %d | HP %d | MP %d" % [
		int(player_data.get("skill_points", 0)),
		int(stats.get("attack_damage", 0)),
		int(player_data.get("max_health", stats.get("max_health", 0))),
		int(player_data.get("max_mana", stats.get("max_mana", 0))),
	]
	var start_text := "%s\n%s" % [
		str(start_options.get("fresh_label", "Enter Tower: Floor 1")),
		str(start_options.get("best_label", "Challenge Best Floor")),
	]
	return {
		"character_text": character_text,
		"progress_text": progress_text,
		"resource_text": resource_text,
		"growth_text": growth_text,
		"start_text": start_text,
		"gear_score": gear_score,
		"gold": gold,
		"crystal": crystal,
		"inventory_items": InventoryDataServiceScript.get_total_items(inventory),
		"inventory_capacity": inventory_capacity,
		"start_options": start_options,
		"recommendations": recommendations,
		"recommendation_text": str(recommendations.get("recommendation_text", "")),
	}

static func _get_total_equipment_score(player_data: Dictionary) -> int:
	var total := 0
	var equipped: Dictionary = Dictionary(player_data.get("equipped_items", {}))
	for slot in GameConstantsScript.EQUIPMENT_SLOTS:
		total += EquipmentDataServiceScript.get_item_score(player_data, str(equipped.get(slot, "")))
	return total

static func _get_inventory_amount(inventory: Dictionary, item_id: String) -> int:
	if not inventory.has(item_id):
		return 0
	return int(Dictionary(inventory[item_id]).get("amount", 0))
