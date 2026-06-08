extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const InventoryEquipmentWindowScript := preload("res://scripts/ui/InventoryEquipmentWindow.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Test", "warrior")
	var better_weapon := {
		"instance_id": "better_weapon",
		"name": "Better Sword",
		"slot": "weapon",
		"equipment_pool": "warrior",
		"affixes": {"attack_damage": 25},
	}
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player["inventory"]), {"id": "better_weapon", "name": "Better Sword", "type": "equipment", "equipment": better_weapon})

	var window := InventoryEquipmentWindowScript.new()
	root.add_child(window)
	window.set_player_data(player)
	await process_frame

	_expect(window.has_method("describe_item_for_test"), "window should expose describe_item_for_test")
	if window.has_method("describe_item_for_test"):
		var text := str(window.call("describe_item_for_test", "better_weapon"))
		_expect(text.contains("Compare"), "equipment detail should include compare section")
		_expect(text.contains("attack_damage") and text.contains("+15"), "compare should show attack damage delta")

	window.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_EQUIPMENT_COMPARE_TEXT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
