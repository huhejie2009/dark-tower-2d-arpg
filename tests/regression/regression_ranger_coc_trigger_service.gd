extends SceneTree

const SkillRulesScript := preload("res://scripts/rules/SkillRules.gd")
const TriggerRuleServiceScript := preload("res://scripts/data/TriggerRuleService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var ice_shot := SkillRulesScript.get_skill("ranger_ice_shot")
	_expect(str(ice_shot.get("name", "")) == "寒冰射击", "ranger_ice_shot should exist")
	_expect(Array(ice_shot.get("tags", [])).has("projectile"), "ice shot should be projectile-tagged")
	_expect(is_equal_approx(float(ice_shot.get("physical_to_cold_ratio", 0.0)), 0.6), "ice shot should convert 60% physical to cold")

	var ice_lance := SkillRulesScript.get_skill("ice_lance")
	_expect(str(ice_lance.get("triggered_by", "")) == "coc", "ice_lance should be CoC-triggered")
	_expect(is_equal_approx(float(ice_lance.get("trigger_cooldown", 0.0)), 0.30), "ice_lance should use 0.30s base trigger cooldown")

	var state := TriggerRuleServiceScript.create_trigger_state()
	var ready := TriggerRuleServiceScript.evaluate_coc_trigger(
		{"skill_id": "ranger_ice_shot", "critical_hit": true, "hit_count": 1},
		{"coc_trigger_cooldown": 0.30},
		state
	)
	_expect(bool(ready.get("triggered", false)), "critical ice shot should trigger when ready")
	_expect(str(ready.get("trigger_skill_id", "")) == "ice_lance", "trigger should resolve ice_lance")
	var blocked := TriggerRuleServiceScript.evaluate_coc_trigger(
		{"skill_id": "ranger_ice_shot", "critical_hit": true, "hit_count": 1},
		{"coc_trigger_cooldown": 0.30},
		Dictionary(ready.get("next_state", {}))
	)
	_expect(not bool(blocked.get("triggered", true)), "second trigger should be blocked by cooldown")
	_expect(str(blocked.get("reason", "")) == "cooldown", "blocked reason should be cooldown")
	var ticked := TriggerRuleServiceScript.tick_trigger_state(Dictionary(ready.get("next_state", {})), 0.31)
	var after_cooldown := TriggerRuleServiceScript.evaluate_coc_trigger(
		{"skill_id": "ranger_ice_shot", "critical_hit": true, "hit_count": 1},
		{"coc_trigger_cooldown": 0.30},
		ticked
	)
	_expect(bool(after_cooldown.get("triggered", false)), "trigger should be ready after cooldown tick")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_RANGER_COC_TRIGGER_SERVICE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
