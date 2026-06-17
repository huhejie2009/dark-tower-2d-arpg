extends SceneTree

const GameConstantsScript := preload("res://scripts/app/GameConstants.gd")
const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")
const TowerRunStartServiceScript := preload("res://scripts/data/TowerRunStartService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := SaveManagerScript.create_character("slot_1", "2.5D Runner", "warrior")
	player["highest_floor"] = 29
	SaveManagerScript.save_active_player_data(player, 29)
	TowerRunStartServiceScript.request_start_floor(29)

	_expect(GameConstantsScript.ACTIVE_GAME_SCENE == GameConstantsScript.PROTOTYPE_2_5D_COMBAT_SCENE, "active game scene should be the accepted 2.5D combat runtime")
	_expect(GameConstantsScript.GAME_2D_SCENE == "res://scenes/Game2D.tscn", "legacy 2D combat scene should remain as fallback")

	var packed := load(GameConstantsScript.ACTIVE_GAME_SCENE)
	_expect(packed is PackedScene, "active 2.5D game scene should load")
	if not packed is PackedScene:
		_finish()
		return

	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame

	_expect(scene.has_method("build_main_flow_migration_snapshot_for_test"), "2.5D runtime should expose main-flow migration snapshot")
	_expect(scene.has_method("_enter_next_floor"), "2.5D runtime should expose next-floor transition")
	_expect(scene.has_method("_return_to_town_for_test"), "2.5D runtime should expose return-to-town save bridge for tests")
	if not scene.has_method("build_main_flow_migration_snapshot_for_test"):
		scene.queue_free()
		await process_frame
		_finish()
		return

	var snapshot: Dictionary = scene.call("build_main_flow_migration_snapshot_for_test")
	_expect(str(snapshot.get("runtime_id", "")) == "prototype_2_5d_main_tower_flow", "2.5D runtime should identify as main tower flow")
	_expect(int(snapshot.get("current_floor", 0)) == 29, "2.5D runtime should consume requested best floor")
	_expect(str(snapshot.get("active_player_name", "")) == "2.5D Runner", "2.5D runtime should load active player data")
	_expect(str(snapshot.get("legacy_fallback_scene", "")) == GameConstantsScript.GAME_2D_SCENE, "2.5D runtime should report legacy fallback scene")
	_expect(bool(snapshot.get("uses_save_manager", false)), "2.5D runtime should use save manager bridge")
	_expect(bool(snapshot.get("uses_tower_run_start_service", false)), "2.5D runtime should use tower run start bridge")
	_expect(int(TowerRunStartServiceScript.consume_start_floor(player)) == 1, "2.5D runtime should consume pending start request once")

	scene.set("exit_unlocked", true)
	scene.call("_enter_next_floor")
	await process_frame
	var after_next: Dictionary = scene.call("build_main_flow_migration_snapshot_for_test")
	_expect(int(after_next.get("current_floor", 0)) == 30, "2.5D next-floor bridge should advance current floor")
	_expect(not bool(after_next.get("exit_unlocked", true)), "2.5D next-floor bridge should consume the unlocked exit")
	var saved_player: Dictionary = SaveManagerScript.get_active_player_data()
	_expect(int(saved_player.get("highest_floor", 0)) >= 30, "2.5D next-floor bridge should save highest floor progress")

	scene.call("_return_to_town_for_test")
	var after_return: Dictionary = SaveManagerScript.get_active_player_data()
	_expect(int(after_return.get("highest_floor", 0)) >= 30, "2.5D return-to-town bridge should preserve progress")

	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_PROTOTYPE_2_5D_MAIN_FLOW_MIGRATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
