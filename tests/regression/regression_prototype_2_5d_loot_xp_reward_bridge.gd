extends SceneTree

const GameConstantsScript := preload("res://scripts/app/GameConstants.gd")
const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")
const TowerRunStartServiceScript := preload("res://scripts/data/TowerRunStartService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := SaveManagerScript.create_character("slot_1", "2.5D Loot", "warrior")
	player["current_exp"] = 90
	player["exp_to_next_level"] = 100
	player["highest_floor"] = 5
	SaveManagerScript.save_active_player_data(player, 5)
	TowerRunStartServiceScript.request_start_floor(5)

	var packed := load(GameConstantsScript.ACTIVE_GAME_SCENE)
	_expect(packed is PackedScene, "active 2.5D game scene should load")
	if not packed is PackedScene:
		_finish()
		return

	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame

	_expect(scene.has_method("build_loot_xp_reward_snapshot_for_test"), "2.5D runtime should expose loot/xp reward snapshot")
	_expect(scene.has_method("defeat_enemy_for_test"), "2.5D runtime should expose enemy defeat hook")
	if not scene.has_method("build_loot_xp_reward_snapshot_for_test"):
		scene.queue_free()
		await process_frame
		_finish()
		return

	var initial: Dictionary = scene.call("build_loot_xp_reward_snapshot_for_test")
	_expect(int(initial.get("current_floor", 0)) == 5, "reward bridge should run on requested floor 5")
	_expect(int(initial.get("floor_kill_count", -1)) == 0, "new floor should start with zero floor kills")
	_expect(int(initial.get("inventory_used_slots", 0)) >= 1, "starter inventory should exist before rewards")
	var initial_living_count := int(initial.get("living_enemy_count", 0))
	_expect(initial_living_count >= 2, "boss floor should spawn a template wave")

	scene.call("defeat_enemy_for_test", 0)
	await process_frame
	var after_first: Dictionary = scene.call("build_loot_xp_reward_snapshot_for_test")
	_expect(int(after_first.get("floor_kill_count", 0)) == 1, "defeating one enemy should increment floor kill count")
	_expect(int(after_first.get("kill_index", 0)) == 1, "defeating one enemy should increment run kill index")
	_expect(int(after_first.get("last_xp_gained", 0)) > 0, "defeating an enemy should grant XP")
	_expect(int(after_first.get("player_level", 0)) >= 2, "near-level player should level from enemy XP")
	_expect(int(after_first.get("inventory_used_slots", 0)) > int(initial.get("inventory_used_slots", 0)), "enemy drop should enter inventory")
	_expect(str(Dictionary(after_first.get("last_loot_notification", {})).get("item_name", "")) != "", "enemy drop should create loot notification")
	_expect(str(after_first.get("hud_status_text", "")).contains("Enemies"), "HUD status should remain synced after reward")
	_expect(str(after_first.get("hud_inventory_text", "")).contains("Bag"), "HUD inventory text should remain synced after reward")

	for index in range(1, initial_living_count):
		scene.call("defeat_enemy_for_test", index)
	await process_frame
	var after_clear: Dictionary = scene.call("build_loot_xp_reward_snapshot_for_test")
	var rewards: Dictionary = Dictionary(after_clear.get("last_floor_rewards", {}))
	_expect(bool(after_clear.get("exit_unlocked", false)), "clearing 2.5D floor should unlock exit")
	_expect(int(after_clear.get("living_enemy_count", -1)) == 0, "cleared 2.5D floor should have zero living enemies")
	_expect(int(rewards.get("floor", 0)) == 5, "floor-clear rewards should record cleared floor")
	_expect(bool(rewards.get("is_boss_floor", false)), "floor 5 should use boss-floor reward rules")
	_expect(Array(rewards.get("guaranteed_items", [])).size() == 1, "boss floor should grant guaranteed equipment")
	_expect(bool(after_clear.get("has_boss_reward_item", false)), "guaranteed boss item should enter inventory")
	_expect(str(Dictionary(after_clear.get("last_loot_notification", {})).get("headline", "")).contains("Boss"), "boss reward should become the last loot notification")

	var saved_player := SaveManagerScript.get_active_player_data()
	_expect(int(saved_player.get("highest_floor", 0)) >= 6, "floor clear should save next-floor progress")
	_expect(int(saved_player.get("player_level", 0)) >= 2, "saved player should keep XP level-up")
	var data := SaveManagerScript.load_save()
	var slot: Dictionary = SaveManagerScript.get_active_slot(data)
	var pending: Dictionary = Dictionary(slot.get("pending_rewards", {}))
	_expect(int(pending.get("gold", 0)) > 0, "floor clear should save pending gold reward")
	_expect(int(pending.get("crystal", 0)) > 0, "boss floor should save pending crystal reward")

	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	root.get_tree().paused = false
	if failures.is_empty():
		print("NEW_PROJECT_PROTOTYPE_2_5D_LOOT_XP_REWARD_BRIDGE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
