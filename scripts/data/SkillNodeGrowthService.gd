extends RefCounted
class_name SkillNodeGrowthService

const NODES := {
	"basic_attack_training": {
		"node_id": "basic_attack_training",
		"title": "基础攻击训练",
		"stat_id": "attack_damage",
		"stat_label": "伤害",
		"stat_gain": 3,
		"max_level": 5,
		"skill_point_cost": 1,
	},
	"vitality_training": {
		"node_id": "vitality_training",
		"title": "生命训练",
		"stat_id": "max_health",
		"stat_label": "生命",
		"stat_gain": 12,
		"max_level": 5,
		"skill_point_cost": 1,
	},
	"precision_training": {
		"node_id": "precision_training",
		"title": "精准训练",
		"stat_id": "critical_chance",
		"stat_label": "暴击",
		"stat_gain": 2,
		"max_level": 5,
		"skill_point_cost": 1,
	},
	"ranger_coc_precision": {
		"node_id": "ranger_coc_precision",
		"title": "触发精准",
		"stat_id": "critical_chance",
		"stat_label": "暴击",
		"stat_gain": 3,
		"max_level": 5,
		"skill_point_cost": 1,
		"class_tag": "ranger",
	},
	"ranger_trigger_flow": {
		"node_id": "ranger_trigger_flow",
		"title": "触发流动",
		"stat_id": "coc_cooldown_recovery",
		"stat_label": "触发恢复",
		"stat_gain": 4,
		"max_level": 3,
		"skill_point_cost": 1,
		"class_tag": "ranger",
	},
	"ranger_ice_mastery": {
		"node_id": "ranger_ice_mastery",
		"title": "冰霜精通",
		"stat_id": "cold_damage",
		"stat_label": "冰冷伤害",
		"stat_gain": 5,
		"max_level": 5,
		"skill_point_cost": 1,
		"class_tag": "ranger",
	},
	"ranger_projectile_split": {
		"node_id": "ranger_projectile_split",
		"title": "分裂冰矢",
		"stat_id": "ice_lance_split",
		"stat_label": "冰矢分裂",
		"stat_gain": 1,
		"max_level": 1,
		"skill_point_cost": 1,
		"class_tag": "ranger",
	},
}

static func list_nodes() -> Array:
	var result: Array = []
	var ids: Array = NODES.keys()
	ids.sort()
	for node_id in ids:
		result.append(Dictionary(NODES[node_id]).duplicate(true))
	return result

static func get_node(node_id: String) -> Dictionary:
	return Dictionary(NODES.get(node_id, {})).duplicate(true)

static func build_preview(player_data: Dictionary, node_id: String) -> Dictionary:
	var node := get_node(node_id)
	if node.is_empty():
		return {"node_id": node_id, "can_upgrade": false, "reason": "unknown_node"}
	var normalized := _normalize_growth_data(player_data)
	var nodes: Dictionary = Dictionary(normalized.get("unlocked_skill_nodes", {}))
	var current_level := clampi(int(nodes.get(node_id, 0)), 0, int(node.get("max_level", 1)))
	var max_level := int(node.get("max_level", 1))
	var next_level := mini(current_level + 1, max_level)
	var cost := int(node.get("skill_point_cost", 1))
	var skill_points := int(normalized.get("skill_points", 0))
	var at_max := current_level >= max_level
	var has_points := skill_points >= cost
	var can_upgrade := has_points and not at_max
	var reason := "ready"
	if at_max:
		reason = "max_level"
	elif not has_points:
		reason = "no_skill_points"
	var stat_label := str(node.get("stat_label", node.get("stat_id", "")))
	var stat_gain := int(node.get("stat_gain", 0))
	return {
		"node_id": node_id,
		"title": str(node.get("title", node_id)),
		"stat_id": str(node.get("stat_id", "")),
		"stat_label": stat_label,
		"current_level": current_level,
		"next_level": next_level,
		"max_level": max_level,
		"skill_points": skill_points,
		"skill_point_cost": cost,
		"stat_gain": stat_gain,
		"damage_gain": stat_gain if str(node.get("stat_id", "")) == "attack_damage" else 0,
		"can_upgrade": can_upgrade,
		"reason": reason,
		"summary_text": _build_summary_text(node, current_level, next_level, max_level),
		"status_text": _build_status_text(can_upgrade, reason, cost),
		"tooltip_text": _build_tooltip_text(node, current_level, next_level, max_level, cost),
	}

static func build_all_previews(player_data: Dictionary) -> Array:
	var previews: Array = []
	for node in list_nodes():
		previews.append(build_preview(player_data, str(Dictionary(node).get("node_id", ""))))
	return previews

static func upgrade_node(player_data: Dictionary, node_id: String) -> Dictionary:
	var preview := build_preview(player_data, node_id)
	var result := _normalize_growth_data(player_data)
	if not bool(preview.get("can_upgrade", false)):
		return {"ok": false, "reason": str(preview.get("reason", "blocked")), "node_id": node_id, "player_data": result}
	var nodes: Dictionary = Dictionary(result.get("unlocked_skill_nodes", {}))
	var next_level := int(preview.get("next_level", 0))
	nodes[node_id] = next_level
	result["unlocked_skill_nodes"] = nodes
	result["skill_points"] = int(result.get("skill_points", 0)) - int(preview.get("skill_point_cost", 1))
	var stat_id := str(preview.get("stat_id", ""))
	var gain := int(preview.get("stat_gain", 0))
	result[stat_id] = int(result.get(stat_id, 0)) + gain
	if stat_id == "max_health":
		result["health"] = clampi(int(result.get("health", 1)) + gain, 1, int(result.get("max_health", 1)))
	return {
		"ok": true,
		"node_id": node_id,
		"node_level": next_level,
		"stat_id": stat_id,
		"stat_gain": gain,
		"player_data": result,
	}

static func reset_skill_nodes(player_data: Dictionary) -> Dictionary:
	var result := _normalize_growth_data(player_data)
	var nodes: Dictionary = Dictionary(result.get("unlocked_skill_nodes", {}))
	var refunded := 0
	for node_id in nodes.keys():
		var node := get_node(str(node_id))
		if node.is_empty():
			continue
		var level := clampi(int(nodes[node_id]), 0, int(node.get("max_level", 1)))
		var cost := int(node.get("skill_point_cost", 1))
		var stat_id := str(node.get("stat_id", ""))
		var stat_gain := int(node.get("stat_gain", 0)) * level
		refunded += level * cost
		if stat_id != "" and stat_gain != 0:
			result[stat_id] = int(result.get(stat_id, 0)) - stat_gain
			if stat_id == "max_health":
				result["max_health"] = maxi(1, int(result.get("max_health", 1)))
				result["health"] = clampi(int(result.get("health", 1)), 1, int(result["max_health"]))
			else:
				result[stat_id] = maxi(0, int(result.get(stat_id, 0)))
	result["unlocked_skill_nodes"] = {}
	result["skill_points"] = int(result.get("skill_points", 0)) + refunded
	return {"ok": true, "refunded_skill_points": refunded, "player_data": result}

static func _normalize_growth_data(player_data: Dictionary) -> Dictionary:
	var result := player_data.duplicate(true)
	result["skill_points"] = maxi(0, int(result.get("skill_points", 0)))
	if not (result.get("unlocked_skill_nodes", {}) is Dictionary):
		result["unlocked_skill_nodes"] = {}
	result["attack_damage"] = int(result.get("attack_damage", 0))
	result["max_health"] = maxi(1, int(result.get("max_health", 1)))
	result["health"] = clampi(int(result.get("health", result["max_health"])), 1, int(result["max_health"]))
	result["critical_chance"] = maxi(0, int(result.get("critical_chance", 0)))
	result["cold_damage"] = maxi(0, int(result.get("cold_damage", 0)))
	result["coc_cooldown_recovery"] = maxi(0, int(result.get("coc_cooldown_recovery", 0)))
	result["ice_lance_split"] = maxi(0, int(result.get("ice_lance_split", 0)))
	return result

static func _build_summary_text(node: Dictionary, current_level: int, next_level: int, max_level: int) -> String:
	var title := str(node.get("title", "技能"))
	var stat_label := str(node.get("stat_label", node.get("stat_id", "")))
	var stat_gain := int(node.get("stat_gain", 0))
	if current_level >= max_level:
		return "%s 等级%d/%d\n已满级\n%s +%d" % [title, current_level, max_level, stat_label, stat_gain]
	return "%s 等级%d/%d\n下级 +%d %s（%s +%d，等级%d）\n消耗 %d 天赋点" % [
		title,
		current_level,
		max_level,
		stat_gain,
		stat_label,
		stat_label,
		stat_gain,
		next_level,
		int(node.get("skill_point_cost", 1)),
	]

static func _build_status_text(can_upgrade: bool, reason: String, cost: int) -> String:
	if can_upgrade:
		return "可以升级"
	if reason == "max_level":
		return "已达到最高等级"
	return "需要 %d 天赋点" % cost

static func _build_tooltip_text(node: Dictionary, current_level: int, next_level: int, max_level: int, cost: int) -> String:
	var title := str(node.get("title", "技能"))
	var stat_label := str(node.get("stat_label", node.get("stat_id", "")))
	var stat_gain := int(node.get("stat_gain", 0))
	if current_level >= max_level:
		return "%s\n等级%d/%d\n已满级" % [title, current_level, max_level]
	return "%s\n等级%d -> 等级%d\n%s +%d\n消耗 %d 天赋点" % [title, current_level, next_level, stat_label, stat_gain, cost]
