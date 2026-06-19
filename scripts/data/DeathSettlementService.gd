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
	var loot_text := "拾取\n%s" % ("无" if pickup_names.is_empty() else ", ".join(_string_array(pickup_names)))
	var action_text := _build_action_text(str(context.get("return_health_mode", "half")))
	var floor_text := "第 %d 层\n房间模板：%s" % [floor, template_id]
	var combat_text := "战斗\n击杀：%d\n返回生命：半血" % kill_count
	var boss_text := "首领奖励\n%s" % boss_reward_text
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
			{"id": "floor", "title": "楼层", "text": floor_text},
			{"id": "combat", "title": "战斗", "text": combat_text},
			{"id": "loot", "title": "拾取", "text": loot_text},
			{"id": "boss_reward", "title": "首领奖励", "text": boss_text},
			{"id": "action", "title": "下一步", "text": action_text},
		],
	}

static func _build_summary_text(floor: int, template_id: String, kill_count: int, pickup_names: Array, boss_reward: bool, boss_reward_text: String) -> String:
	var lines: Array[String] = [
		"你倒在第 %d 层。" % floor,
		"房间模板：%s" % template_id,
		"击杀：%d" % kill_count,
		"角色将半血返回主城。",
	]
	if pickup_names.is_empty():
		lines.append("拾取：无")
	else:
		lines.append("拾取：%s" % ", ".join(_string_array(pickup_names)))
	if boss_reward:
		lines.append("首领奖励：%s" % boss_reward_text)
	return "\n".join(lines)

static func _build_boss_reward_text(rewards: Dictionary) -> String:
	if not bool(rewards.get("is_boss_floor", false)):
		return "无"
	var guaranteed: Array = Array(rewards.get("guaranteed_items", []))
	if guaranteed.is_empty():
		return "待结算"
	var names: Array[String] = []
	for item in guaranteed:
		names.append(str(Dictionary(item).get("name", "首领奖励")))
	return ", ".join(names)

static func _build_action_text(return_health_mode: String) -> String:
	if return_health_mode == "half":
		return "半血返回主城。背包与装备会保留。"
	return "返回主城。背包与装备会保留。"

static func _string_array(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(str(value))
	return result
