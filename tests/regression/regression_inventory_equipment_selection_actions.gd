extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const InventoryEquipmentWindowScript := preload("res://scripts/ui/InventoryEquipmentWindow.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Test", "warrior")
	var starter_weapon_id := str(Dictionary(player.get("equipped_items", {})).get("weapon", ""))
	var better_weapon := {
		"instance_id": "better_weapon",
		"name": "Better Sword",
		"slot": "weapon",
		"equipment_pool": "warrior",
		"item_level": 3,
		"rarity": "magic",
		"affixes": {"attack_damage": 25},
	}
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player["inventory"]), {
		"id": "better_weapon",
		"name": "Better Sword",
		"type": "equipment",
		"equipment": better_weapon,
	})

	var window := InventoryEquipmentWindowScript.new()
	root.add_child(window)
	window.set_player_data(player)
	await process_frame

	_expect(window.find_child("EquipSelectedButton", true, false) != null, "selected equip action should exist")
	_expect(window.find_child("LockSelectedButton", true, false) != null, "selected lock action should exist")
	_expect(window.has_method("select_item"), "window should expose select_item")
	_expect(window.has_method("use_selected_item"), "window should expose use_selected_item")
	_expect(window.has_method("toggle_selected_lock"), "window should expose toggle_selected_lock")
	_expect(window.has_method("get_selected_item_id"), "window should expose get_selected_item_id")
	_expect(window.has_method("get_item_score_for_test"), "window should expose item score helper")

	if window.has_method("select_item"):
		window.call("select_item", "better_weapon")
		await process_frame
		_expect(str(window.call("get_selected_item_id")) == "better_weapon", "select_item should store selected item id")
		var after_select: Dictionary = Dictionary(window.get("player_data"))
		_expect(str(Dictionary(after_select.get("equipped_items", {})).get("weapon", "")) == starter_weapon_id, "selecting an item should not auto-equip it")
		var detail := str(window.find_child("ItemDetail", true, false).get("text"))
		_expect(detail.contains("Score"), "selected equipment detail should include score")

	if window.has_method("use_selected_item"):
		window.call("use_selected_item")
		await process_frame
		var after_use: Dictionary = Dictionary(window.get("player_data"))
		_expect(str(Dictionary(after_use.get("equipped_items", {})).get("weapon", "")) == "better_weapon", "use_selected_item should equip the selected equipment")

	if window.has_method("toggle_selected_lock"):
		window.call("toggle_selected_lock")
		var updated: Dictionary = Dictionary(window.get("player_data"))
		var entry: Dictionary = Dictionary(Dictionary(updated.get("inventory", {})).get("better_weapon", {}))
		_expect(bool(entry.get("locked", false)), "toggle_selected_lock should lock the selected item")

	if window.has_method("get_item_score_for_test"):
		_expect(int(window.call("get_item_score_for_test", "better_weapon")) > 0, "equipment score should be positive")

	window.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_INVENTORY_EQUIPMENT_SELECTION_ACTIONS_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
