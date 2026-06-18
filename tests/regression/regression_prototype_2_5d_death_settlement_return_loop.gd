extends SceneTree

const GameConstantsScript := preload("res://scripts/app/GameConstants.gd")
const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")
const TowerRunStartServiceScript := preload("res://scripts/data/TowerRunStartService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := SaveManagerScript.create_character("slot_1", "2.5D Death", "warrior")
	player["health"] = 6
	player["max_health"] = 120
	player["highest_floor"] = 8
	SaveManagerScript.save_active_player_data(player, 8)
	TowerRunStartServiceScript.request_start_floor(8)

	var packed := load(GameConstantsScript.ACTIVE_GAME_SCENE)
	_expect(packed is PackedScene, "active 2.5D game scene should load")
	if not packed is PackedScene:
		_finish()
		return

	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame

	_expect(scene.has_method("build_death_settlement_snapshot_for_test"), "2.5D runtime should expose death settlement snapshot")
	_expect(scene.has_method("force_enemy_attack_player_for_test"), "2.5D runtime should expose deterministic enemy attack hook")
	_expect(scene.has_method("_return_to_town_after_death_for_test"), "2.5D runtime should expose death return save hook")
	if not scene.has_method("build_death_settlement_snapshot_for_test"):
		scene.queue_free()
		await process_frame
		_finish()
		return

	var initial: Dictionary = scene.call("build_death_settlement_snapshot_for_test")
	_expect(not bool(initial.get("death_settlement_active", true)), "2.5D death settlement should start inactive")
	_expect(not bool(initial.get("death_overlay_visible", true)), "2.5D death overlay should start hidden")
	_expect(not bool(initial.get("tree_paused", true)), "2.5D runtime should start unpaused before death")
	_expect(int(initial.get("player_health", 0)) == 6, "2.5D runtime should use saved player health")

	scene.call("force_enemy_attack_player_for_test", 0)
	await process_frame
	var after_death: Dictionary = scene.call("build_death_settlement_snapshot_for_test")
	_expect(bool(after_death.get("death_settlement_active", false)), "enemy damage should activate death settlement")
	_expect(bool(after_death.get("death_overlay_visible", false)), "death settlement should show overlay")
	_expect(bool(after_death.get("tree_paused", false)), "death settlement should pause combat")
	_expect(bool(after_death.get("menu_blocks_combat", false)), "death settlement should block combat input")
	_expect(int(after_death.get("player_health", -1)) == 0, "runtime player health should reach zero on death")
	_expect(int(after_death.get("saved_player_health", 0)) == 60, "saved player should return with half health")
	_expect(str(after_death.get("settlement_summary", "")).contains("floor 8"), "settlement summary should mention death floor")
	_expect(str(after_death.get("settlement_loot_text", "")).contains("Loot"), "settlement should expose loot section")

	scene.call("force_enemy_attack_player_for_test", 0)
	await process_frame
	var after_repeat: Dictionary = scene.call("build_death_settlement_snapshot_for_test")
	_expect(int(after_repeat.get("death_trigger_count", 0)) == 1, "death settlement should trigger only once")
	_expect(int(after_repeat.get("player_health", -1)) == 0, "repeat attacks should not change dead runtime health")

	scene.call("_return_to_town_after_death_for_test")
	await process_frame
	var after_return: Dictionary = scene.call("build_death_settlement_snapshot_for_test")
	_expect(not bool(after_return.get("tree_paused", true)), "death return test hook should unpause the tree")
	_expect(int(after_return.get("saved_player_health", 0)) == 60, "death return should preserve half-health save")

	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	root.get_tree().paused = false
	if failures.is_empty():
		print("NEW_PROJECT_PROTOTYPE_2_5D_DEATH_SETTLEMENT_RETURN_LOOP_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
