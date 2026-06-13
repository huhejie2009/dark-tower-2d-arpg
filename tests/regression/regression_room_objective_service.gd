extends SceneTree

const RoomObjectiveServiceScript := preload("res://scripts/data/RoomObjectiveService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var clear_state := RoomObjectiveServiceScript.build_state({
		"floor": 2,
		"template_id": "dense_room",
		"objective": "clear_all",
		"enemies": [{}, {}, {}, {}],
	})
	_expect(str(clear_state.get("objective_id", "")) == "clear_all", "clear_all objective id should be preserved")
	_expect(int(clear_state.get("target_count", 0)) == 4, "clear_all target should equal enemy count")
	_expect(str(clear_state.get("hud_text", "")).contains("Clear enemies"), "clear_all HUD text should be readable")
	clear_state = RoomObjectiveServiceScript.record_enemy_defeated(clear_state, {"is_elite": false, "is_boss": false})
	_expect(int(clear_state.get("current_count", 0)) == 1, "enemy defeat should advance clear objective")
	_expect(not bool(clear_state.get("completed", true)), "objective should not complete early")
	clear_state = RoomObjectiveServiceScript.record_enemy_defeated(clear_state, {})
	clear_state = RoomObjectiveServiceScript.record_enemy_defeated(clear_state, {})
	clear_state = RoomObjectiveServiceScript.record_enemy_defeated(clear_state, {})
	_expect(bool(clear_state.get("completed", false)), "clear objective should complete at target count")

	var elite_state := RoomObjectiveServiceScript.build_state({
		"floor": 5,
		"template_id": "elite_preview",
		"objective": "defeat_elite",
		"enemies": [{}, {"modifiers": {"elite_affixes": ["tough"]}}, {}],
	})
	_expect(int(elite_state.get("target_count", 0)) == 1, "elite objective should target elite count")
	elite_state = RoomObjectiveServiceScript.record_enemy_defeated(elite_state, {"is_elite": false})
	_expect(not bool(elite_state.get("completed", true)), "normal kill should not complete elite objective")
	elite_state = RoomObjectiveServiceScript.record_enemy_defeated(elite_state, {"is_elite": true})
	_expect(bool(elite_state.get("completed", false)), "elite kill should complete elite objective")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_ROOM_OBJECTIVE_SERVICE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
