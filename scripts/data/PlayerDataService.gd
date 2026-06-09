extends RefCounted
class_name PlayerDataService

const ClassRulesScript := preload("res://scripts/rules/ClassRules.gd")
const EquipmentAffixRulesScript := preload("res://scripts/rules/EquipmentAffixRules.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const EquipmentDataServiceScript := preload("res://scripts/data/EquipmentDataService.gd")
const SkillNodeGrowthServiceScript := preload("res://scripts/data/SkillNodeGrowthService.gd")

const BASIC_ATTACK_TRAINING_NODE := "basic_attack_training"
const BASIC_ATTACK_TRAINING_MAX_LEVEL := 5
const BASIC_ATTACK_TRAINING_DAMAGE_GAIN := 3

static func build_starter_player(slot_id: String, character_name: String, base_class: String) -> Dictionary:
	var normalized_class: String = ClassRulesScript.normalize_class(base_class)
	var class_data: Dictionary = ClassRulesScript.get_class_data(normalized_class)
	var starter_weapon_id: String = str(class_data.get("starter_weapon", "starter_warrior_sword"))
	var starter_equipment: Dictionary = EquipmentAffixRulesScript.build_starter_equipment(starter_weapon_id)
	var inventory: Dictionary = {}
	inventory = InventoryDataServiceScript.add_item(inventory, {
		"id": starter_weapon_id,
		"name": str(starter_equipment.get("name", starter_weapon_id)),
		"type": "equipment",
		"equipment": starter_equipment,
	})
	return {
		"slot_id": slot_id,
		"character_name": character_name if character_name.strip_edges() != "" else "New Hero",
		"base_class": normalized_class,
		"advanced_class": "",
		"player_level": 1,
		"current_exp": 0,
		"exp_to_next_level": 100,
		"max_health": int(class_data.get("max_health", 120)),
		"health": int(class_data.get("max_health", 120)),
		"max_mana": int(class_data.get("max_mana", 60)),
		"mana": int(class_data.get("max_mana", 60)),
		"attack_damage": int(class_data.get("attack_damage", 24)),
		"skill_points": 0,
		"unlocked_skill_nodes": {},
		"active_skill_id": "whirlwind_core" if normalized_class == "warrior" else "",
		"inventory": inventory,
		"equipped_items": EquipmentDataServiceScript.normalize_equipped_items({"weapon": starter_weapon_id}),
		"highest_floor": 1,
	}

static func normalize_player_data(data: Variant) -> Dictionary:
	if not (data is Dictionary):
		return build_starter_player("slot_1", "New Hero", "warrior")
	var result: Dictionary = Dictionary(data).duplicate(true)
	result["base_class"] = ClassRulesScript.normalize_class(str(result.get("base_class", "warrior")))
	result["player_level"] = maxi(1, int(result.get("player_level", 1)))
	result["current_exp"] = maxi(0, int(result.get("current_exp", 0)))
	result["exp_to_next_level"] = maxi(1, int(result.get("exp_to_next_level", _build_exp_to_next_level(int(result["player_level"])))))
	result["skill_points"] = maxi(0, int(result.get("skill_points", 0)))
	if not (result.get("unlocked_skill_nodes", {}) is Dictionary):
		result["unlocked_skill_nodes"] = {}
	result["max_health"] = maxi(1, int(result.get("max_health", 100)))
	result["health"] = clampi(int(result.get("health", result["max_health"])), 1, int(result["max_health"]))
	result["max_mana"] = maxi(1, int(result.get("max_mana", 50)))
	result["mana"] = clampi(int(result.get("mana", result["max_mana"])), 0, int(result["max_mana"]))
	result["inventory"] = InventoryDataServiceScript.normalize_inventory(result.get("inventory", {}))
	result["equipped_items"] = EquipmentDataServiceScript.normalize_equipped_items(result.get("equipped_items", {}))
	return result

static func get_combat_stats(player_data: Dictionary) -> Dictionary:
	return EquipmentDataServiceScript.build_stat_totals(normalize_player_data(player_data))

static func add_experience(player_data: Dictionary, amount: int) -> Dictionary:
	var result := normalize_player_data(player_data)
	var gained := maxi(0, amount)
	if gained <= 0:
		return result
	result["current_exp"] = int(result.get("current_exp", 0)) + gained
	while int(result.get("current_exp", 0)) >= int(result.get("exp_to_next_level", 100)):
		result["current_exp"] = int(result["current_exp"]) - int(result["exp_to_next_level"])
		_apply_level_up(result)
	return result

static func _apply_level_up(player_data: Dictionary) -> void:
	var next_level := int(player_data.get("player_level", 1)) + 1
	var health_gain := 8
	var mana_gain := 4
	var attack_gain := 2
	player_data["player_level"] = next_level
	player_data["skill_points"] = int(player_data.get("skill_points", 0)) + 1
	player_data["max_health"] = int(player_data.get("max_health", 100)) + health_gain
	player_data["health"] = clampi(int(player_data.get("health", 1)) + health_gain, 1, int(player_data["max_health"]))
	player_data["max_mana"] = int(player_data.get("max_mana", 50)) + mana_gain
	player_data["mana"] = clampi(int(player_data.get("mana", 0)) + mana_gain, 0, int(player_data["max_mana"]))
	player_data["attack_damage"] = int(player_data.get("attack_damage", 20)) + attack_gain
	player_data["exp_to_next_level"] = _build_exp_to_next_level(next_level)

static func _build_exp_to_next_level(level: int) -> int:
	var safe_level := maxi(1, level)
	return 100 + (safe_level - 1) * 45

static func upgrade_basic_attack(player_data: Dictionary) -> Dictionary:
	return SkillNodeGrowthServiceScript.upgrade_node(player_data, BASIC_ATTACK_TRAINING_NODE)
