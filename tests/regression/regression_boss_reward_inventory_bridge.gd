extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const GameScene := preload("res://scenes/Game2D.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := GameScene.instantiate()
	root.add_child(scene)
	await process_frame
	_expect(scene.has_method("_build_floor_clear_rewards_for_test"), "Game2D should expose floor reward builder")
	_expect(scene.has_method("_apply_floor_clear_rewards_to_player_for_test"), "Game2D should expose floor reward inventory bridge")
	if scene.has_method("_build_floor_clear_rewards_for_test") and scene.has_method("_apply_floor_clear_rewards_to_player_for_test"):
		var player := PlayerDataServiceScript.build_starter_player("slot_1", "Test", "warrior")
		var before_count := Dictionary(player.get("inventory", {})).size()
		var rewards: Dictionary = Dictionary(scene.call("_build_floor_clear_rewards_for_test", 5, "warrior"))
		_expect(Array(rewards.get("guaranteed_items", [])).size() == 1, "boss reward should include one guaranteed item")
		var updated: Dictionary = Dictionary(scene.call("_apply_floor_clear_rewards_to_player_for_test", player, rewards))
		var inventory: Dictionary = Dictionary(updated.get("inventory", {}))
		_expect(inventory.size() == before_count + 1, "boss guaranteed item should enter inventory")
		var found_magic_or_better := false
		for item_id in inventory.keys():
			var entry: Dictionary = Dictionary(inventory[item_id])
			var equipment: Dictionary = Dictionary(entry.get("equipment", {}))
			if ["magic", "rare", "legendary"].has(str(equipment.get("rarity", ""))) and str(equipment.get("template_id", "")) == "boss_clear_reward":
				found_magic_or_better = true
		_expect(found_magic_or_better, "inventory should contain boss magic-or-better equipment")
	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_BOSS_REWARD_INVENTORY_BRIDGE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
