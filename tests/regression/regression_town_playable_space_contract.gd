extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/Town.tscn")
	_expect(packed is PackedScene, "Town should load")
	if packed is PackedScene:
		var town: Node = packed.instantiate()
		root.add_child(town)
		await process_frame
		_expect(town.find_child("TownWorldRoot", true, false) != null, "town should expose a playable world root")
		_expect(town.find_child("TownPlayer", true, false) != null, "town should expose a movable player avatar")
		_expect(town.find_child("TownTowerGateInteraction", true, false) != null, "town should expose tower gate interaction")
		_expect(town.find_child("TownMerchantInteraction", true, false) != null, "town should expose merchant interaction anchor")
		_expect(town.find_child("TownBlacksmithInteraction", true, false) != null, "town should expose blacksmith interaction anchor")
		_expect(town.find_child("TownStashInteraction", true, false) != null, "town should expose stash interaction anchor")
		_expect(town.find_child("TownTrainingInteraction", true, false) != null, "town should expose training interaction anchor")
		_expect(town.has_method("get_town_interaction_points_for_test"), "town should expose interaction point contract")
		_expect(town.has_method("move_town_player_for_test"), "town should expose player movement test hook")
		_expect(town.has_method("get_town_player_position_for_test"), "town should expose player position test hook")
		_expect(town.has_method("trigger_town_interaction_for_test"), "town should expose interaction trigger hook")
		if town.has_method("get_town_interaction_points_for_test"):
			var points: Dictionary = Dictionary(town.call("get_town_interaction_points_for_test"))
			for key in ["tower_gate", "merchant", "blacksmith", "stash", "training"]:
				_expect(points.has(key), "town interaction map should include %s" % key)
				_expect(str(Dictionary(points.get(key, {})).get("display_name", "")) != "", "%s should have display name" % key)
		if town.has_method("get_town_player_position_for_test") and town.has_method("move_town_player_for_test"):
			var before: Vector2 = town.call("get_town_player_position_for_test")
			town.call("move_town_player_for_test", Vector2.RIGHT, 0.35)
			var after: Vector2 = town.call("get_town_player_position_for_test")
			_expect(after.x > before.x + 8.0, "town player should move through playable space")
		if town.has_method("trigger_town_interaction_for_test"):
			town.call("trigger_town_interaction_for_test", "merchant")
			await process_frame
			var inventory := town.find_child("InventoryEquipmentWindow", true, false) as Control
			var facility := town.find_child("TownFacilityWindow", true, false) as Control
			_expect(facility != null and facility.visible, "merchant should open a town facility panel")
			_expect(inventory != null and not inventory.visible, "merchant should not immediately force inventory open")
		town.queue_free()
		await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_TOWN_PLAYABLE_SPACE_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
