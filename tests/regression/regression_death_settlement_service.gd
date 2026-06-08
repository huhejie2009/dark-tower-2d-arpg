extends SceneTree

const DeathSettlementServiceScript := preload("res://scripts/data/DeathSettlementService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var context := {
		"floor": 5,
		"template_id": "boss_gatekeeper",
		"kill_count": 4,
		"pickup_names": ["Gold", "Gatekeeper Trophy 5"],
		"last_floor_rewards": {"is_boss_floor": true, "guaranteed_items": [{"name": "Gatekeeper Trophy 5"}]},
		"return_health_mode": "half",
	}
	var settlement: Dictionary = DeathSettlementServiceScript.build_death_settlement(context)
	_expect(str(settlement.get("floor_text", "")).contains("boss_gatekeeper"), "floor text should include template id")
	_expect(str(settlement.get("combat_text", "")).contains("4"), "combat text should include kill count")
	_expect(str(settlement.get("loot_text", "")).contains("Gold"), "loot text should include picked item")
	_expect(str(settlement.get("boss_reward_text", "")).contains("Gatekeeper Trophy 5"), "boss text should include boss reward")
	_expect(str(settlement.get("summary_text", "")).contains("Boss reward"), "summary should include boss reward")
	_expect(str(settlement.get("action_text", "")).contains("half health"), "action should explain return health")
	_expect(Array(settlement.get("sections", [])).size() >= 5, "settlement should expose structured sections")
	_expect(bool(settlement.get("boss_reward", false)), "settlement should flag boss reward")

	var empty_context := {
		"floor": 2,
		"template_id": "clear_room",
		"kill_count": 0,
		"pickup_names": [],
		"last_floor_rewards": {},
	}
	var empty_settlement: Dictionary = DeathSettlementServiceScript.build_death_settlement(empty_context)
	_expect(str(empty_settlement.get("loot_text", "")).contains("none"), "empty loot text should be explicit")
	_expect(not bool(empty_settlement.get("boss_reward", true)), "non-boss settlement should not flag boss reward")

	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_DEATH_SETTLEMENT_SERVICE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
