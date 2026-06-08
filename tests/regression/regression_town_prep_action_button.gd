extends SceneTree

const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := SaveManagerScript.create_character("slot_1", "Prep Action", "warrior")
	player["skill_points"] = 2
	player["highest_floor"] = 7
	SaveManagerScript.save_active_player_data(player, 7)

	var packed := load("res://scenes/Town.tscn")
	_expect(packed is PackedScene, "Town should load")
	if packed is PackedScene:
		var town: Node = packed.instantiate()
		root.add_child(town)
		await process_frame
		var action_button := town.find_child("TownPrepActionButton", true, false) as Button
		var inventory := town.find_child("InventoryEquipmentWindow", true, false) as Control
		_expect(action_button != null, "town prep panel should expose an action button")
		_expect(inventory != null, "town should still own inventory equipment window")
		if action_button != null:
			_expect(str(action_button.text) == "Open Skills", "skill recommendation should drive prep action button text")
			_expect(not action_button.disabled, "prep action button should be enabled when action exists")
			action_button.pressed.emit()
			await process_frame
			if inventory != null:
				_expect(inventory.visible, "prep action button should open inventory equipment window")
				_expect(inventory.has_method("get_selected_skill_node_id"), "inventory should expose selected skill target")
				if inventory.has_method("get_selected_skill_node_id"):
					_expect(str(inventory.call("get_selected_skill_node_id")) == "basic_attack_training", "skill action should focus default skill node")
		town.queue_free()
		await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_TOWN_PREP_ACTION_BUTTON_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
