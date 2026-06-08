extends SceneTree

const Game2DScene := preload("res://scenes/Game2D.tscn")
const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := Game2DScene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.set("player_data", PlayerDataServiceScript.build_starter_player("slot_1", "Test", "warrior"))

	_expect(scene.has_method("_build_loot_notification_for_test"), "Game2D should expose loot notification builder")
	_expect(scene.has_method("_get_last_loot_notification_for_test"), "Game2D should expose last loot notification")
	_expect(scene.has_method("_on_drop_collected"), "Game2D should keep drop collection bridge")

	if scene.has_method("_build_loot_notification_for_test"):
		var payload := {
			"id": "better_weapon",
			"name": "Better Sword",
			"type": "equipment",
			"amount": 1,
			"equipment": {
				"instance_id": "better_weapon",
				"name": "Better Sword",
				"slot": "weapon",
				"equipment_pool": "warrior",
				"item_level": 4,
				"rarity": "magic",
				"affixes": {"attack_damage": 28},
			},
		}
		var note: Dictionary = Dictionary(scene.call("_build_loot_notification_for_test", payload, "drop"))
		_expect(bool(note.get("upgrade", false)), "Game2D loot notification should mark better equipment")
		scene.call("_on_drop_collected", payload)
		await process_frame
		var last: Dictionary = Dictionary(scene.call("_get_last_loot_notification_for_test"))
		_expect(str(last.get("item_name", "")) == "Better Sword", "last loot notification should store picked item")
		var hud := scene.find_child("HudController", true, false)
		_expect(hud != null, "Game2D should have HUD")
		if hud != null and hud.has_method("get_last_loot_notification_for_test"):
			var hud_last: Dictionary = Dictionary(hud.call("get_last_loot_notification_for_test"))
			_expect(str(hud_last.get("item_name", "")) == "Better Sword", "HUD should receive picked item notification")

	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_GAME2D_LOOT_NOTIFICATION_BRIDGE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
