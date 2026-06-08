extends SceneTree

const Game2DScene := preload("res://scenes/Game2D.tscn")

func _initialize() -> void:
	var scene := Game2DScene.instantiate()
	root.add_child(scene)
	await process_frame

	_expect(scene.has_method("_toggle_pause_for_test"), "Game2D should expose pause toggle for focus tests")
	_expect(scene.has_method("_show_death_settlement_for_test"), "Game2D should expose death settlement show for focus tests")
	_expect(scene.has_method("_handle_cancel_for_test"), "Game2D should expose cancel handling for tests")

	if scene.has_method("_toggle_pause_for_test"):
		scene.call("_toggle_pause_for_test")
		await process_frame
		var pause_focus := root.get_viewport().gui_get_focus_owner()
		_expect(pause_focus != null and pause_focus.name == "ResumeButton", "pause overlay should focus resume button")

	if scene.has_method("_handle_cancel_for_test"):
		var inventory := scene.find_child("InventoryEquipmentWindow", true, false) as Control
		_expect(inventory != null, "inventory window should exist")
		if inventory != null:
			inventory.visible = true
			scene.call("_handle_cancel_for_test")
			await process_frame
			_expect(not inventory.visible, "cancel should close inventory before changing pause state")

	if scene.has_method("_show_death_settlement_for_test"):
		scene.call("_show_death_settlement_for_test")
		await process_frame
		var death_focus := root.get_viewport().gui_get_focus_owner()
		_expect(death_focus != null and death_focus.name == "DeathReturnTownButton", "death settlement should focus return town button")

	scene.queue_free()
	await process_frame
	print("NEW_PROJECT_MENU_FOCUS_AND_CANCEL_OK")
	quit(0)

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
