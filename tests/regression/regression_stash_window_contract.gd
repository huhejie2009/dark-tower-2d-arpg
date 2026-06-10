extends SceneTree

const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := SaveManagerScript.create_character("slot_1", "Stash UI", "warrior")
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player.get("inventory", {})), {
		"id": "stash_test_crystal",
		"name": "Stash Crystal",
		"type": "material",
		"amount": 5,
	})
	SaveManagerScript.save_active_player_data(player, 1)
	SaveManagerScript.save_active_stash({})

	var packed := load("res://scenes/Town.tscn")
	_expect(packed is PackedScene, "Town should load")
	if packed is PackedScene:
		var town: Node = packed.instantiate()
		root.add_child(town)
		await process_frame
		town.call("trigger_town_interaction_for_test", "stash")
		await process_frame
		town.call("trigger_town_facility_action_for_test", "stash", "open_stash")
		await process_frame
		var stash_window := town.find_child("StashWindow", true, false) as Control
		var facility_window := town.find_child("TownFacilityWindow", true, false) as Control
		var inventory := town.find_child("InventoryEquipmentWindow", true, false) as Control
		_expect(stash_window != null and stash_window.visible, "stash facility action should open stash window")
		_expect(facility_window != null and not facility_window.visible, "opening stash should close the facility panel")
		_expect(inventory != null and not inventory.visible, "stash window should not force inventory window open")
		if stash_window != null:
			var rect := stash_window.get_global_rect()
			_expect(rect.position.x >= 0.0 and rect.position.y >= 0.0, "stash window should not be clipped off the top-left screen edge")
			_expect(rect.end.x <= 1280.0 and rect.end.y <= 720.0, "stash window should fit inside 1280x720")
			_expect(stash_window.has_method("deposit_item_for_test"), "stash window should expose deposit test hook")
			_expect(stash_window.has_method("withdraw_item_for_test"), "stash window should expose withdraw test hook")
			stash_window.call("deposit_item_for_test", "stash_test_crystal")
			await process_frame
			var bag_ids: Array = Array(stash_window.call("get_visible_bag_item_ids_for_test"))
			var stash_ids: Array = Array(stash_window.call("get_visible_stash_item_ids_for_test"))
			_expect(not bag_ids.has("stash_test_crystal"), "deposit should remove item from visible bag list")
			_expect(stash_ids.has("stash_test_crystal"), "deposit should add item to visible stash list")
			stash_window.call("withdraw_item_for_test", "stash_test_crystal")
			await process_frame
			bag_ids = Array(stash_window.call("get_visible_bag_item_ids_for_test"))
			stash_ids = Array(stash_window.call("get_visible_stash_item_ids_for_test"))
			_expect(bag_ids.has("stash_test_crystal"), "withdraw should return item to visible bag list")
			_expect(not stash_ids.has("stash_test_crystal"), "withdraw should remove item from visible stash list")
		town.queue_free()
		await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_STASH_WINDOW_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
