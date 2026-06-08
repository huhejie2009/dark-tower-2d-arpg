extends SceneTree

const P2LootLoopAcceptanceServiceScript := preload("res://scripts/data/P2LootLoopAcceptanceService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var checklist: Dictionary = P2LootLoopAcceptanceServiceScript.build_acceptance()
	_expect(str(checklist.get("phase_id", "")) == "P2", "checklist should identify P2")
	_expect(int(checklist.get("target_minutes", 0)) == 10, "P2 loot loop target should be 10 minutes")
	_expect(Array(checklist.get("items", [])).size() >= 6, "checklist should include core loot loop items")
	_expect(str(checklist.get("pass_rule", "")).contains("loot"), "pass rule should mention loot loop")

	var item_ids: Array[String] = []
	for item in Array(checklist.get("items", [])):
		var entry: Dictionary = Dictionary(item)
		item_ids.append(str(entry.get("id", "")))
		_expect(str(entry.get("metric_key", "")) != "", "each item should include metric key")
		_expect(str(entry.get("acceptance", "")) != "", "each item should include acceptance text")
		_expect(str(entry.get("failure_hint", "")) != "", "each item should include failure hint")
	_expect(item_ids.has("P2-LOOP-FLOOR"), "checklist should cover floor progress")
	_expect(item_ids.has("P2-LOOP-LOOT"), "checklist should cover pickup volume")
	_expect(item_ids.has("P2-LOOP-UPGRADE"), "checklist should cover upgrade candidates")
	_expect(item_ids.has("P2-LOOP-EQUIP"), "checklist should cover actual equipment change")
	_expect(item_ids.has("P2-LOOP-SKILL"), "checklist should cover skill progression")
	_expect(item_ids.has("P2-LOOP-STABILITY"), "checklist should cover blocking defects")

	var passing_metrics := {
		"minutes_played": 10,
		"floors_cleared": 3,
		"items_picked": 8,
		"equipment_picked": 2,
		"upgrade_candidates_seen": 1,
		"equipment_changes": 1,
		"skill_upgrades": 1,
		"deaths": 1,
		"p0_defects": 0,
		"p1_defects": 1,
		"regression_passed": true,
		"headless_exit_zero": true,
	}
	var report: Dictionary = P2LootLoopAcceptanceServiceScript.evaluate_metrics(passing_metrics)
	_expect(bool(report.get("passed", false)), "healthy loot loop metrics should pass")
	_expect(float(report.get("completion_ratio", 0.0)) >= 1.0, "passing report should have full completion ratio")
	_expect(Array(report.get("failed_items", [])).is_empty(), "passing report should not include failed items")
	_expect(str(report.get("summary_text", "")).contains("loot loop ready"), "passing summary should be readable")
	_expect(str(report.get("next_focus", "")) != "", "report should include next focus")

	var blocked_metrics := {
		"minutes_played": 10,
		"floors_cleared": 1,
		"items_picked": 2,
		"equipment_picked": 0,
		"upgrade_candidates_seen": 0,
		"equipment_changes": 0,
		"skill_upgrades": 0,
		"p0_defects": 1,
		"p1_defects": 0,
		"regression_passed": true,
		"headless_exit_zero": true,
	}
	var blocked: Dictionary = P2LootLoopAcceptanceServiceScript.evaluate_metrics(blocked_metrics)
	_expect(not bool(blocked.get("passed", true)), "blocked loot loop metrics should fail")
	_expect(Array(blocked.get("failed_items", [])).size() >= 4, "blocked report should list failed goals")
	_expect(str(blocked.get("summary_text", "")).contains("blocked"), "blocked summary should be readable")
	_expect(Array(blocked.get("next_actions", [])).size() >= 2, "blocked report should provide next actions")

	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_P2_LOOT_LOOP_ACCEPTANCE_SERVICE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
