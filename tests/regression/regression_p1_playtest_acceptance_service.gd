extends SceneTree

const PlaytestAcceptanceServiceScript := preload("res://scripts/data/PlaytestAcceptanceService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var checklist: Dictionary = PlaytestAcceptanceServiceScript.build_phase_acceptance("P1")
	_expect(str(checklist.get("phase_id", "")) == "P1", "acceptance checklist should identify P1")
	_expect(str(checklist.get("phase_name", "")).contains("UI"), "P1 checklist should include phase name")
	_expect(int(checklist.get("target_minutes", 0)) >= 30, "P1 playtest target should be at least 30 minutes")
	_expect(Array(checklist.get("items", [])).size() >= 8, "P1 checklist should include enough hands-on items")
	_expect(Array(checklist.get("gates", [])).size() >= 4, "P1 checklist should include gates")
	_expect(str(checklist.get("pass_rule", "")).contains("P0"), "P1 pass rule should mention blocker severity")

	var item_ids: Array[String] = []
	for item in Array(checklist.get("items", [])):
		var entry: Dictionary = Dictionary(item)
		item_ids.append(str(entry.get("id", "")))
		_expect(str(entry.get("owner", "")) != "", "each item should include owner role")
		_expect(str(entry.get("acceptance", "")) != "", "each item should include acceptance text")
		_expect(str(entry.get("verification", "")) != "", "each item should include verification guidance")
	_expect(item_ids.has("P1-INV-001"), "checklist should cover inventory operations")
	_expect(item_ids.has("P1-EQP-001"), "checklist should cover equipment paper doll")
	_expect(item_ids.has("P1-LOOT-001"), "checklist should cover loot notification")
	_expect(item_ids.has("P1-DEATH-001"), "checklist should cover death settlement")
	_expect(item_ids.has("P1-SAVE-001"), "checklist should cover save safety")

	var report: Dictionary = PlaytestAcceptanceServiceScript.evaluate_phase_report("P1", {
		"P0": 0,
		"P1": 1,
		"P2": 4,
		"minutes_played": 35,
		"regression_passed": true,
		"headless_exit_zero": true,
	})
	_expect(bool(report.get("passed", false)), "P1 should pass with no P0 and limited P1 defects")
	_expect(str(report.get("next_phase", "")) == "P2", "P1 pass report should point to P2")

	var blocked: Dictionary = PlaytestAcceptanceServiceScript.evaluate_phase_report("P1", {
		"P0": 1,
		"P1": 0,
		"P2": 0,
		"minutes_played": 35,
		"regression_passed": true,
		"headless_exit_zero": true,
	})
	_expect(not bool(blocked.get("passed", true)), "P1 should fail with any P0 defect")

	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_P1_PLAYTEST_ACCEPTANCE_SERVICE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
