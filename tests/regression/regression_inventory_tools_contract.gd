extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const InventoryEquipmentWindowScript := preload("res://scripts/ui/InventoryEquipmentWindow.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Test", "warrior")
	var armor := {
		"instance_id": "armor_test",
		"name": "Test Armor",
		"slot": "armor",
		"equipment_pool": "warrior",
		"affixes": {"defense": 4},
		"locked": false,
	}
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player["inventory"]), {"id": "armor_test", "name": "Test Armor", "type": "equipment", "equipment": armor})

	var window := InventoryEquipmentWindowScript.new()
	root.add_child(window)
	window.set_player_data(player)
	await process_frame

	_expect(window.find_child("SortInventoryButton", true, false) != null, "sort button should exist")
	_expect(window.find_child("FilterAllButton", true, false) != null, "all filter should exist")
	_expect(window.find_child("FilterEquipmentButton", true, false) != null, "equipment filter should exist")
	_expect(window.find_child("FilterMaterialButton", true, false) != null, "material filter should exist")
	_expect(window.has_method("toggle_item_lock"), "window should expose toggle_item_lock")
	_expect(window.has_method("get_visible_item_ids"), "window should expose visible item ids")
	var all_filter := window.find_child("FilterAllButton", true, false) as Button
	var equipment_filter := window.find_child("FilterEquipmentButton", true, false) as Button
	var material_filter := window.find_child("FilterMaterialButton", true, false) as Button
	if all_filter != null and equipment_filter != null and material_filter != null:
		_expect(all_filter.toggle_mode, "all filter should expose selected state")
		_expect(equipment_filter.toggle_mode, "equipment filter should expose selected state")
		_expect(material_filter.toggle_mode, "material filter should expose selected state")
		_expect(all_filter.button_pressed, "all filter should start selected")
		_expect(not equipment_filter.button_pressed, "equipment filter should start unselected")
		_expect(not material_filter.button_pressed, "material filter should start unselected")

	if window.has_method("toggle_item_lock"):
		window.call("toggle_item_lock", "armor_test")
		var updated: Dictionary = Dictionary(window.get("player_data"))
		var entry: Dictionary = Dictionary(Dictionary(updated.get("inventory", {})).get("armor_test", {}))
		_expect(bool(entry.get("locked", false)), "lock should be stored on inventory entry")

	if window.has_method("set_filter_mode") and window.has_method("get_visible_item_ids"):
		window.call("set_filter_mode", "material")
		var visible_materials: Array = Array(window.call("get_visible_item_ids"))
		_expect(not visible_materials.has("armor_test"), "equipment should be hidden by material filter")
		if all_filter != null and equipment_filter != null and material_filter != null:
			_expect(material_filter.button_pressed, "material filter should become selected")
			_expect(not all_filter.button_pressed, "all filter should unselect after material filter")
			_expect(not equipment_filter.button_pressed, "equipment filter should remain unselected after material filter")
		window.call("set_filter_mode", "equipment")
		var visible_equipment: Array = Array(window.call("get_visible_item_ids"))
		_expect(visible_equipment.has("armor_test"), "equipment should show in equipment filter")
		if all_filter != null and equipment_filter != null and material_filter != null:
			_expect(equipment_filter.button_pressed, "equipment filter should become selected")
			_expect(not all_filter.button_pressed, "all filter should remain unselected after equipment filter")
			_expect(not material_filter.button_pressed, "material filter should unselect after equipment filter")

	window.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_INVENTORY_TOOLS_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
