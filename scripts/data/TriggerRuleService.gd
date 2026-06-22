extends RefCounted
class_name TriggerRuleService

const SkillRulesScript := preload("res://scripts/rules/SkillRules.gd")

static func create_trigger_state() -> Dictionary:
	return {"cooldowns": {}}

static func tick_trigger_state(state: Dictionary, delta: float) -> Dictionary:
	var result := state.duplicate(true)
	var cooldowns: Dictionary = Dictionary(result.get("cooldowns", {}))
	for key in cooldowns.keys():
		cooldowns[key] = maxf(0.0, float(cooldowns[key]) - maxf(0.0, delta))
	result["cooldowns"] = cooldowns
	return result

static func evaluate_coc_trigger(attack_result: Dictionary, stats: Dictionary, state: Dictionary) -> Dictionary:
	if str(attack_result.get("skill_id", "")) != "ranger_ice_shot":
		return _blocked("wrong_skill", state)
	if int(attack_result.get("hit_count", 0)) <= 0:
		return _blocked("no_hit", state)
	if not bool(attack_result.get("critical_hit", false)):
		return _blocked("not_critical", state)
	var trigger_skill_id := str(SkillRulesScript.get_skill("ranger_ice_shot").get("coc_trigger_skill_id", "ice_lance"))
	var skill := SkillRulesScript.get_skill(trigger_skill_id)
	if str(skill.get("triggered_by", "")) != "coc":
		return _blocked("bad_trigger_skill", state)
	var cooldown := maxf(0.05, float(stats.get("coc_trigger_cooldown", skill.get("trigger_cooldown", 0.30))))
	var cooldowns: Dictionary = Dictionary(state.get("cooldowns", {}))
	if float(cooldowns.get(trigger_skill_id, 0.0)) > 0.0:
		return _blocked("cooldown", state)
	var next_state := state.duplicate(true)
	var next_cooldowns: Dictionary = Dictionary(next_state.get("cooldowns", {}))
	next_cooldowns[trigger_skill_id] = cooldown
	next_state["cooldowns"] = next_cooldowns
	return {
		"triggered": true,
		"reason": "ready",
		"trigger_skill_id": trigger_skill_id,
		"cooldown": cooldown,
		"next_state": next_state,
	}

static func _blocked(reason: String, state: Dictionary) -> Dictionary:
	return {"triggered": false, "reason": reason, "next_state": state.duplicate(true)}
