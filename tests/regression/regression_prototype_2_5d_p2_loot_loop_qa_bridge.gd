extends SceneTree

const GameConstantsScript := preload("res://scripts/app/GameConstants.gd")
const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")
const TowerRunStartServiceScript := preload("res://scripts/data/TowerRunStartService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := SaveManagerScript.create_character("slot_1", "2.5D P2 QA", "warrior")
	player["health"] = 220
	player["max_health"] = 220
	player["mana"] = 80
	player["max_mana"] = 80
	player["highest_floor"] = 5
	SaveManagerScript.save_active_player_data(player, 1)
	TowerRunStartServiceScript.request_start_floor(1)

	var packed := load(GameConstantsScript.ACTIVE_GAME_SCENE)
	_expect(packed is PackedScene, "active 2.5D game scene should load")
	if not packed is PackedScene:
		_finish()
		return

	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame

	_expect(scene.has_method("build_p2_loot_loop_qa_snapshot_for_test"), "2.5D runtime should expose P2 loot loop QA snapshot")
	_expect(scene.has_method("set_p2_loot_loop_elapsed_seconds_for_test"), "2.5D runtime should expose P2 elapsed time hook")
	_expect(scene.has_method("set_p2_loot_loop_verification_gates_for_test"), "2.5D runtime should expose P2 verification gate hook")
	_expect(scene.has_method("record_equipment_change_for_test"), "2.5D runtime should expose equipment change hook")
	_expect(scene.has_method("defeat_enemy_for_test"), "2.5D runtime should expose enemy defeat hook")
	_expect(scene.has_method("enter_next_floor_for_test"), "2.5D runtime should expose next-floor hook")
	if not scene.has_method("build_p2_loot_loop_qa_snapshot_for_test"):
		scene.queue_free()
		await process_frame
		_finish()
		return

	scene.call("set_p2_loot_loop_elapsed_seconds_for_test", 603.0)
	scene.call("set_p2_loot_loop_verification_gates_for_test", true, true)

	for floor in [1, 2, 3, 4, 5]:
		_clear_current_floor(scene)
		if floor < 5:
			scene.call("enter_next_floor_for_test")
			await process_frame
			await physics_frame

	scene.call("record_equipment_change_for_test")
	await process_frame

	var snapshot: Dictionary = Dictionary(scene.call("build_p2_loot_loop_qa_snapshot_for_test"))
	var metrics: Dictionary = Dictionary(snapshot.get("metrics", {}))
	var report: Dictionary = Dictionary(snapshot.get("acceptance_report", {}))

	_expect(int(snapshot.get("current_floor", 0)) == 5, "P2 QA should end on floor 5 after deterministic climb")
	_expect(int(snapshot.get("start_floor", 0)) == 1, "P2 QA should remember requested start floor")
	_expect(str(snapshot.get("start_floor_source", "")) != "", "P2 QA should explain the start-floor source")
	_expect(int(snapshot.get("player_highest_floor", 0)) >= 6, "P2 QA should expose saved highest-floor progress after boss clear")
	_expect(str(snapshot.get("highest_floor_explanation", "")).contains("highest_floor"), "P2 QA should explain high-floor starts")
	_expect(str(snapshot.get("objective_text", "")) != "", "P2 QA should expose current HUD objective")
	_expect(not Dictionary(snapshot.get("last_loot_notification", {})).is_empty(), "P2 QA should expose last loot notification")

	_expect(int(metrics.get("minutes_played", 0)) == 10, "P2 QA metrics should normalize 603 seconds to 10 minutes")
	_expect(int(metrics.get("floors_cleared", 0)) >= 5, "P2 QA metrics should count cleared floors")
	_expect(int(metrics.get("items_picked", 0)) >= 8, "P2 QA metrics should count sustained pickups")
	_expect(int(metrics.get("equipment_picked", 0)) >= 1, "P2 QA metrics should count equipment pickups")
	_expect(int(metrics.get("upgrade_candidates_seen", 0)) >= 1, "P2 QA metrics should count upgrade candidates")
	_expect(int(metrics.get("equipment_changes", 0)) >= 1, "P2 QA metrics should count equipment changes")
	_expect(int(metrics.get("p0_defects", 0)) == 0, "P2 QA metrics should start with zero P0 defects")
	_expect(bool(metrics.get("regression_passed", false)), "P2 QA metrics should carry regression gate")
	_expect(bool(metrics.get("headless_exit_zero", false)), "P2 QA metrics should carry headless gate")

	_expect(str(report.get("phase_id", "")) == "P2", "P2 QA report should come from acceptance service")
	_expect(bool(report.get("passed", false)), "P2 QA report should pass after deterministic 1-5 loop and verification gates")
	_expect(str(report.get("summary_text", "")).contains("loot loop ready"), "P2 QA report should have readable success summary")

	scene.queue_free()
	await process_frame
	_finish()

func _clear_current_floor(scene: Node) -> void:
	var snapshot: Dictionary = scene.call("build_floor_pacing_snapshot_for_test")
	for index in range(int(snapshot.get("total_enemy_count", 0))):
		scene.call("defeat_enemy_for_test", index)

func _finish() -> void:
	root.get_tree().paused = false
	if failures.is_empty():
		print("NEW_PROJECT_PROTOTYPE_2_5D_P2_LOOT_LOOP_QA_BRIDGE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
