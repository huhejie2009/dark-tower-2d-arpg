extends RefCounted
class_name DeathSettlementService

static func build_death_settlement(context: Dictionary) -> Dictionary:
	var floor := maxi(1, int(context.get("floor", 1)))
	var template_id := str(context.get("template_id", "unknown"))
	var kill_count := maxi(0, int(context.get("kill_count", 0)))
	var pickup_names: Array = Array(context.get("pickup_names", []))
	var rewards: Dictionary = Dictionary(context.get("last_floor_rewards", {}))
	var boss_reward := bool(rewards.get("is_boss_floor", false))
	var boss_reward_text := _build_boss_reward_text(rewards)
	var loot_text := "Loot\n%s" % ("none" if pickup_names.is_empty() else ", ".join(_string_array(pickup_names)))
	var action_text := _build_action_text(str(context.get("return_health_mode", "half")))
	var floor_text := "Floor %d\nTemplate: %s" % [floor, template_id]
	var combat_text := "Combat\nKills: %d\nReturn health: half" % kill_count
	var boss_text := "Boss reward\n%s" % boss_reward_text
	var summary_text := _build_summary_text(floor, template_id, kill_count, pickup_names, boss_reward, boss_reward_text)
	return {
		"floor": floor,
		"template_id": template_id,
		"kill_count": kill_count,
		"pickup_names": _string_array(pickup_names),
		"boss_reward": boss_reward,
		"floor_text": floor_text,
		"combat_text": combat_text,
		"loot_text": loot_text,
		"boss_reward_text": boss_text,
		"summary_text": summary_text,
		"action_text": action_text,
		"sections": [
			{"id": "floor", "title": "Floor", "text": floor_text},
			{"id": "combat", "title": "Combat", "text": combat_text},
			{"id": "loot", "title": "Loot", "text": loot_text},
			{"id": "boss_reward", "title": "Boss reward", "text": boss_text},
			{"id": "action", "title": "Next step", "text": action_text},
		],
	}

static func _build_summary_text(floor: int, template_id: String, kill_count: int, pickup_names: Array, boss_reward: bool, boss_reward_text: String) -> String:
	var lines: Array[String] = [
		"You fell on floor %d." % floor,
		"Template: %s" % template_id,
		"Kills: %d" % kill_count,
		"Your hero returns to town with half health.",
	]
	if pickup_names.is_empty():
		lines.append("Picked: none")
	else:
		lines.append("Picked: %s" % ", ".join(_string_array(pickup_names)))
	if boss_reward:
		lines.append("Boss reward: %s" % boss_reward_text)
	return "\n".join(lines)

static func _build_boss_reward_text(rewards: Dictionary) -> String:
	if not bool(rewards.get("is_boss_floor", false)):
		return "none"
	var guaranteed: Array = Array(rewards.get("guaranteed_items", []))
	if guaranteed.is_empty():
		return "pending"
	var names: Array[String] = []
	for item in guaranteed:
		names.append(str(Dictionary(item).get("name", "Boss Reward")))
	return ", ".join(names)

static func _build_action_text(return_health_mode: String) -> String:
	if return_health_mode == "half":
		return "Return to town with half health. Inventory and equipment are preserved."
	return "Return to town. Inventory and equipment are preserved."

static func _string_array(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(str(value))
	return result
