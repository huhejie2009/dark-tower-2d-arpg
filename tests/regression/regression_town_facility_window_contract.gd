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
		_expect(town.find_child("TownFacilityWindow", true, false) != null, "town should expose facility window")
		_expect(town.has_method("get_open_town_facility_id_for_test"), "town should expose open facility test hook")
		_expect(town.has_method("trigger_town_facility_action_for_test"), "town should expose facility action test hook")
		var inventory := town.find_child("InventoryEquipmentWindow", true, false) as Control
		var facility_window := town.find_child("TownFacilityWindow", true, false) as Control
		for id in ["merchant", "blacksmith", "stash", "training"]:
			town.call("trigger_town_interaction_for_test", id)
			await process_frame
			_expect(town.call("get_open_town_facility_id_for_test") == id, "%s should open its own facility panel" % id)
			_expect(facility_window != null and facility_window.visible, "%s facility panel should be visible" % id)
			_expect(inventory != null and not inventory.visible, "%s should not immediately force the inventory window open" % id)
			if facility_window != null:
				var rect := facility_window.get_global_rect()
				_expect(rect.position.x >= 0.0 and rect.position.y >= 0.0, "%s facility panel should not be clipped off the top-left screen edge" % id)
				_expect(rect.end.x <= 860.0 and rect.end.y <= 716.0, "%s facility panel should stay inside the left playable screen lane" % id)
		town.call("trigger_town_facility_action_for_test", "merchant", "open_inventory")
		await process_frame
		_expect(inventory != null and inventory.visible, "merchant open_inventory action should bridge into inventory window")
		town.queue_free()
		await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_TOWN_FACILITY_WINDOW_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
