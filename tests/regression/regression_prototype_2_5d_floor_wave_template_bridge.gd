extends SceneTree

const GameConstantsScript := preload("res://scripts/app/GameConstants.gd")
const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")
const TowerRunStartServiceScript := preload("res://scripts/data/TowerRunStartService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await _check_floor(1, "melee_intro", ["rot_melee"], false)
	await _check_floor(3, "ranged_pressure", ["shadow_archer", "rot_melee"], false)
	await _check_floor(4, "mixed_pressure", ["tower_guardian", "shadow_archer", "rot_melee"], false)
	await _check_floor(5, "boss_gatekeeper", ["tower_gatekeeper", "rot_melee"], true)
	_finish()

func _check_floor(floor: int, expected_template: String, expected_types: Array[String], expects_boss: bool) -> void:
	var player := SaveManagerScript.create_character("slot_1", "2.5D Waves", "warrior")
	player["highest_floor"] = max(floor, int(player.get("highest_floor", 1)))
	SaveManagerScript.save_active_player_data(player, floor)
	TowerRunStartServiceScript.request_start_floor(floor)

	var packed := load(GameConstantsScript.ACTIVE_GAME_SCENE)
	_expect(packed is PackedScene, "active 2.5D game scene should load")
	if not packed is PackedScene:
		return

	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame

	_expect(scene.has_method("build_floor_wave_snapshot_for_test"), "2.5D runtime should expose floor wave snapshot")
	_expect(scene.has_method("_apply_floor_template_for_test"), "2.5D runtime should expose floor template test hook")
	if not scene.has_method("build_floor_wave_snapshot_for_test"):
		scene.queue_free()
		await process_frame
		return

	var snapshot: Dictionary = scene.call("build_floor_wave_snapshot_for_test")
	_expect(int(snapshot.get("current_floor", 0)) == floor, "2.5D wave bridge should run on requested floor %d" % floor)
	_expect(str(snapshot.get("template_id", "")) == expected_template, "floor %d should use template %s" % [floor, expected_template])
	_expect(int(snapshot.get("template_enemy_count", 0)) == int(snapshot.get("total_enemy_count", -1)), "floor %d should spawn every template enemy" % floor)
	_expect(str(snapshot.get("objective_text", "")).begins_with("目标："), "floor %d should expose objective HUD text" % floor)
	_expect(bool(snapshot.get("has_room_objective_state", false)), "floor %d should build objective state" % floor)
	_expect(bool(snapshot.get("has_boss", false)) == expects_boss, "floor %d boss presence should match template" % floor)

	var enemy_types: Array = Array(snapshot.get("enemy_types", []))
	for expected_type in expected_types:
		_expect(enemy_types.has(expected_type), "floor %d should include enemy type %s" % [floor, expected_type])

	var enemy_positions: Array = Array(snapshot.get("enemy_positions", []))
	_expect(enemy_positions.size() == int(snapshot.get("total_enemy_count", 0)), "floor %d should expose one position per enemy" % floor)
	for position in enemy_positions:
		var pos: Vector3 = position
		_expect(absf(pos.x) <= 8.15, "floor %d enemy x should stay inside 2.5D room bounds" % floor)
		_expect(absf(pos.z) <= 5.15, "floor %d enemy z should stay inside 2.5D room bounds" % floor)

	scene.call("_apply_floor_template_for_test", floor)
	await process_frame
	var reapplied: Dictionary = scene.call("build_floor_wave_snapshot_for_test")
	_expect(str(reapplied.get("template_id", "")) == expected_template, "reapplying floor %d should keep deterministic template" % floor)

	scene.queue_free()
	await process_frame
	root.get_tree().paused = false

func _finish() -> void:
	root.get_tree().paused = false
	if failures.is_empty():
		print("NEW_PROJECT_PROTOTYPE_2_5D_FLOOR_WAVE_TEMPLATE_BRIDGE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
