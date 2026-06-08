extends SceneTree

const P2LootLoopMetricsRecorderScript := preload("res://scripts/data/P2LootLoopMetricsRecorder.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var metrics: Dictionary = P2LootLoopMetricsRecorderScript.create_metrics()
	_expect(int(metrics.get("minutes_played", -1)) == 0, "new metrics should start with zero minutes")
	_expect(int(metrics.get("floors_cleared", -1)) == 0, "new metrics should start with zero floors")
	_expect(int(metrics.get("items_picked", -1)) == 0, "new metrics should start with zero pickups")

	metrics = P2LootLoopMetricsRecorderScript.record_elapsed_seconds(metrics, 602.0)
	metrics = P2LootLoopMetricsRecorderScript.record_floor_cleared(metrics)
	metrics = P2LootLoopMetricsRecorderScript.record_floor_cleared(metrics)
	metrics = P2LootLoopMetricsRecorderScript.record_floor_cleared(metrics)

	var equipment_payload := {
		"id": "test_sword",
		"name": "Test Sword",
		"type": "equipment",
		"equipment": {"slot": "weapon", "rarity": "magic"},
	}
	var upgrade_notification := {
		"upgrade": true,
		"recommendation_rank": "strong_upgrade",
	}
	metrics = P2LootLoopMetricsRecorderScript.record_pickup(metrics, equipment_payload, upgrade_notification)
	for i in range(7):
		metrics = P2LootLoopMetricsRecorderScript.record_pickup(metrics, {"id": "gold_%d" % i, "type": "currency"}, {})
	metrics = P2LootLoopMetricsRecorderScript.record_equipment_change(metrics)
	metrics = P2LootLoopMetricsRecorderScript.record_skill_upgrade(metrics)
	metrics = P2LootLoopMetricsRecorderScript.set_verification_gates(metrics, true, true)

	_expect(int(metrics.get("minutes_played", 0)) == 10, "elapsed seconds should convert to whole minutes")
	_expect(int(metrics.get("floors_cleared", 0)) == 3, "floor clear events should be counted")
	_expect(int(metrics.get("items_picked", 0)) == 8, "pickup events should be counted")
	_expect(int(metrics.get("equipment_picked", 0)) == 1, "equipment pickups should be counted separately")
	_expect(int(metrics.get("upgrade_candidates_seen", 0)) == 1, "upgrade recommendation pickups should be counted")
	_expect(int(metrics.get("equipment_changes", 0)) == 1, "equipment changes should be counted")
	_expect(int(metrics.get("skill_upgrades", 0)) == 1, "skill upgrades should be counted")

	var report: Dictionary = P2LootLoopMetricsRecorderScript.build_acceptance_report(metrics)
	_expect(bool(report.get("passed", false)), "complete recorded metrics should pass P2 acceptance")

	var blocked := P2LootLoopMetricsRecorderScript.record_defect(P2LootLoopMetricsRecorderScript.create_metrics(), "P0")
	var blocked_report: Dictionary = P2LootLoopMetricsRecorderScript.build_acceptance_report(blocked)
	_expect(int(blocked.get("p0_defects", 0)) == 1, "P0 defects should be tracked")
	_expect(not bool(blocked_report.get("passed", true)), "P0 defect metrics should block acceptance")

	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("FOCUSED_P2_LOOT_LOOP_METRICS_RECORDER_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
