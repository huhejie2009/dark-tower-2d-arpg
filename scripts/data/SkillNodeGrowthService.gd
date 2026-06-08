extends RefCounted
class_name SkillNodeGrowthService

const NODES := {
	"basic_attack_training": {
		"node_id": "basic_attack_training",
		"title": "Basic Attack Training",
		"stat_id": "attack_damage",
		"stat_label": "Damage",
		"stat_gain": 3,
		"max_level": 5,
		"skill_point_cost": 1,
	},
	"vitality_training": {
		"node_id": "vitality_training",
		"title": "Vitality Training",
		"stat_id": "max_health",
		"stat_label": "Health",
		"stat_gain": 12,
		"max_level": 5,
		"skill_point_cost": 1,
	},
	"precision_training": {
		"node_id": "precision_training",
		"title": "Precision Training",
		"stat_id": "critical_chance",
		"stat_label": "Crit",
		"stat_gain": 2,
		"max_level": 5,
		"skill_point_cost": 1,
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

static func _normalize_growth_data(player_data: Dictionary) -> Dictionary:
	var result := player_data.duplicate(true)
	result["skill_points"] = maxi(0, int(result.get("skill_points", 0)))
	if not (result.get("unlocked_skill_nodes", {}) is Dictionary):
		result["unlocked_skill_nodes"] = {}
	result["attack_damage"] = int(result.get("attack_damage", 0))
	result["max_health"] = maxi(1, int(result.get("max_health", 1)))
	result["health"] = clampi(int(result.get("health", result["max_health"])), 1, int(result["max_health"]))
	result["critical_chance"] = maxi(0, int(result.get("critical_chance", 0)))
	return result

static func _build_summary_text(node: Dictionary, current_level: int, next_level: int, max_level: int) -> String:
	var title := str(node.get("title", "Skill"))
	var stat_label := str(node.get("stat_label", node.get("stat_id", "")))
	var stat_gain := int(node.get("stat_gain", 0))
	if current_level >= max_level:
		return "%s Lv.%d/%d\nMax Level\n%s +%d" % [title, current_level, max_level, stat_label, stat_gain]
	return "%s Lv.%d/%d\nNext +%d %s (%s +%d, Lv.%d)\nCost %d SP" % [
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
		return "Ready to upgrade"
	if reason == "max_level":
		return "Max level reached"
	return "Need %d SP" % cost

static func _build_tooltip_text(node: Dictionary, current_level: int, next_level: int, max_level: int, cost: int) -> String:
	var title := str(node.get("title", "Skill"))
	var stat_label := str(node.get("stat_label", node.get("stat_id", "")))
	var stat_gain := int(node.get("stat_gain", 0))
	if current_level >= max_level:
		return "%s\nLv.%d/%d\nMax Level" % [title, current_level, max_level]
	return "%s\nLv.%d -> Lv.%d\n%s +%d\nCost %d SP" % [title, current_level, next_level, stat_label, stat_gain, cost]
