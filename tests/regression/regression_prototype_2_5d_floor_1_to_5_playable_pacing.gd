extends SceneTree

const GameConstantsScript := preload("res://scripts/app/GameConstants.gd")
const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")
const TowerRunStartServiceScript := preload("res://scripts/data/TowerRunStartService.gd")

var failures: Array[String] = []

const EXPECTED := {
	1: {
		"template_id": "melee_intro",
		"pacing_role": "movement_attack_intro",
		"enemy_count": 2,
		"types": ["rot_melee"],
		"objective_id": "clear_all",
		"boss": false,
	},
	2: {
		"template_id": "melee_density",
		"pacing_role": "positioning_pressure",
		"enemy_count": 4,
		"types": ["rot_melee"],
		"objective_id": "clear_all",
		"boss": false,
	},
	3: {
		"template_id": "ranged_pressure",
		"pacing_role": "ranged_dodge_intro",
		"enemy_count": 3,
		"types": ["shadow_archer", "rot_melee"],
		"objective_id": "clear_all",
		"boss": false,
	},
	4: {
		"template_id": "mixed_pressure",
		"pacing_role": "mixed_threat_pressure",
		"enemy_count": 4,
		"types": ["tower_guardian", "shadow_archer", "rot_melee"],
		"objective_id": "clear_all",
		"boss": false,
	},
	5: {
		"template_id": "boss_gatekeeper",
		"pacing_role": "gatekeeper_boss_check",
		"enemy_count": 3,
		"types": ["tower_gatekeeper", "rot_melee"],
		"objective_id": "defeat_boss",
		"boss": true,
	},
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := SaveManagerScript.create_character("slot_1", "2.5D Pacing", "warrior")
	player["health"] = 180
	player["max_health"] = 180
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

	_expect(scene.has_method("build_floor_pacing_snapshot_for_test"), "2.5D runtime should expose floor pacing snapshot")
	_expect(scene.has_method("defeat_enemy_for_test"), "2.5D runtime should expose defeat hook")
	_expect(scene.has_method("enter_next_floor_for_test"), "2.5D runtime should expose next-floor hook")
	if not scene.has_method("build_floor_pacing_snapshot_for_test"):
		scene.queue_free()
		await process_frame
		_finish()
		return

	for floor in [1, 2, 3, 4, 5]:
		var snapshot: Dictionary = scene.call("build_floor_pacing_snapshot_for_test")
		_check_floor_snapshot(snapshot, floor)
		_clear_current_floor(scene)
		var cleared: Dictionary = scene.call("build_floor_pacing_snapshot_for_test")
		_expect(bool(cleared.get("exit_unlocked", false)), "floor %d should unlock exit after required kills" % floor)
		_expect(str(cleared.get("objective_text", "")).contains("进入蓝色出口标记"), "floor %d should tell player to enter exit after clear" % floor)
		if floor < 5:
			scene.call("enter_next_floor_for_test")
			await process_frame
			await physics_frame
			var next_snapshot: Dictionary = scene.call("build_floor_pacing_snapshot_for_test")
			_expect(int(next_snapshot.get("current_floor", 0)) == floor + 1, "continuous climb should enter floor %d" % (floor + 1))

	var final_snapshot: Dictionary = scene.call("build_floor_pacing_snapshot_for_test")
	_expect(int(final_snapshot.get("current_floor", 0)) == 5, "1-5 pacing loop should end on floor 5 after boss clear")
	_expect(bool(final_snapshot.get("has_boss", false)), "final floor should remain identified as boss floor")

	scene.queue_free()
	await process_frame
	_finish()

func _check_floor_snapshot(snapshot: Dictionary, floor: int) -> void:
	var expected: Dictionary = Dictionary(EXPECTED[floor])
	_expect(int(snapshot.get("current_floor", 0)) == floor, "snapshot should report floor %d" % floor)
	_expect(str(snapshot.get("template_id", "")) == str(expected.get("template_id", "")), "floor %d should use expected template" % floor)
	_expect(str(snapshot.get("pacing_role", "")) == str(expected.get("pacing_role", "")), "floor %d should expose pacing role" % floor)
	_expect(int(snapshot.get("difficulty_step", 0)) == floor, "floor %d should expose difficulty step" % floor)
	_expect(int(snapshot.get("total_enemy_count", 0)) == int(expected.get("enemy_count", 0)), "floor %d should have intended enemy count" % floor)
	_expect(int(snapshot.get("living_enemy_count", 0)) == int(expected.get("enemy_count", 0)), "floor %d should start with all enemies alive" % floor)
	_expect(str(snapshot.get("objective_id", "")) == str(expected.get("objective_id", "")), "floor %d should use intended objective id" % floor)
	_expect(bool(snapshot.get("has_boss", false)) == bool(expected.get("boss", false)), "floor %d boss flag should match pacing plan" % floor)
	_expect(str(snapshot.get("floor_goal_hint", "")).length() >= 6, "floor %d should expose a readable goal hint" % floor)
	_expect(str(snapshot.get("objective_text", "")).contains(str(snapshot.get("floor_goal_hint", ""))), "floor %d objective should include goal hint" % floor)
	_expect(str(snapshot.get("floor_start_message", "")).contains("第 %d 层" % floor), "floor %d start message should name the floor" % floor)
	var enemy_types: Array = Array(snapshot.get("enemy_types", []))
	for expected_type in Array(expected.get("types", [])):
		_expect(enemy_types.has(expected_type), "floor %d should include %s" % [floor, expected_type])
	var total_damage := int(snapshot.get("total_enemy_attack_damage", 0))
	_expect(total_damage > 0 and total_damage <= int(snapshot.get("player_max_health", 1)), "floor %d total opening damage should stay readable" % floor)

func _clear_current_floor(scene: Node) -> void:
	var snapshot: Dictionary = scene.call("build_floor_pacing_snapshot_for_test")
	for index in range(int(snapshot.get("total_enemy_count", 0))):
		scene.call("defeat_enemy_for_test", index)

func _finish() -> void:
	root.get_tree().paused = false
	if failures.is_empty():
		print("NEW_PROJECT_PROTOTYPE_2_5D_FLOOR_1_TO_5_PLAYABLE_PACING_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
