extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const InventoryEquipmentWindowScript := preload("res://scripts/ui/InventoryEquipmentWindow.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Flag Filters", "warrior")
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player["inventory"]), _equipment_payload("better_weapon", "Better Sword", "weapon", 8, {"attack_damage": 30}))
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player["inventory"]), _equipment_payload("junk_armor", "Junk Armor", "armor", 1, {"defense": 1}))

	var window := InventoryEquipmentWindowScript.new()
	root.add_child(window)
	window.set_player_data(player)
	await process_frame

	_expect(window.find_child("FilterUpgradeButton", true, false) != null, "upgrade filter button should exist")
	_expect(window.find_child("FilterLockedButton", true, false) != null, "locked filter button should exist")
	_expect(window.find_child("FilterFavoriteButton", true, false) != null, "favorite filter button should exist")
	_expect(window.find_child("FilterJunkButton", true, false) != null, "junk filter button should exist")
	_expect(window.find_child("FavoriteSelectedButton", true, false) != null, "favorite selected action should exist")
	_expect(window.find_child("JunkSelectedButton", true, false) != null, "junk selected action should exist")
	_expect(window.has_method("toggle_item_favorite"), "window should expose toggle_item_favorite")
	_expect(window.has_method("toggle_item_junk"), "window should expose toggle_item_junk")

	if window.has_method("toggle_item_favorite") and window.has_method("toggle_item_junk"):
		window.call("toggle_item_favorite", "better_weapon")
		window.call("toggle_item_junk", "junk_armor")
		var updated: Dictionary = Dictionary(window.get("player_data"))
		var better_entry: Dictionary = Dictionary(Dictionary(updated.get("inventory", {})).get("better_weapon", {}))
		var junk_entry: Dictionary = Dictionary(Dictionary(updated.get("inventory", {})).get("junk_armor", {}))
		_expect(bool(Dictionary(better_entry.get("binding_flags", {})).get("favorite", false)), "favorite flag should be stored in binding_flags")
		_expect(bool(Dictionary(junk_entry.get("binding_flags", {})).get("junk", false)), "junk flag should be stored in binding_flags")

	if window.has_method("set_filter_mode") and window.has_method("get_visible_item_ids"):
		window.call("set_filter_mode", "upgrade")
		var upgrade_ids: Array = Array(window.call("get_visible_item_ids"))
		_expect(upgrade_ids.has("better_weapon"), "upgrade filter should show upgrade candidate")
		window.call("set_filter_mode", "favorite")
		var favorite_ids: Array = Array(window.call("get_visible_item_ids"))
		_expect(_same_ids(favorite_ids, ["better_weapon"]), "favorite filter should show favorite item")
		window.call("set_filter_mode", "junk")
		var junk_ids: Array = Array(window.call("get_visible_item_ids"))
		_expect(_same_ids(junk_ids, ["junk_armor"]), "junk filter should show junk item")

	var favorite_filter := window.find_child("FilterFavoriteButton", true, false) as Button
	var junk_filter := window.find_child("FilterJunkButton", true, false) as Button
	if favorite_filter != null and junk_filter != null:
		window.call("set_filter_mode", "favorite")
		_expect(favorite_filter.button_pressed, "favorite filter button should become selected")
		_expect(not junk_filter.button_pressed, "junk filter should unselect when favorite is selected")

	window.queue_free()
	await process_frame
	_finish()

func _equipment_payload(id: String, item_name: String, slot: String, level: int, affixes: Dictionary) -> Dictionary:
	return {
		"id": id,
		"name": item_name,
		"type": "equipment",
		"equipment": {
			"instance_id": id,
			"name": item_name,
			"slot": slot,
			"equipment_pool": "warrior",
			"item_level": level,
			"rarity": "magic",
			"affixes": affixes,
		},
	}

func _same_ids(actual: Array, expected: Array) -> bool:
	var actual_sorted := actual.duplicate()
	var expected_sorted := expected.duplicate()
	actual_sorted.sort()
	expected_sorted.sort()
	if actual_sorted.size() != expected_sorted.size():
		return false
	for i in range(actual_sorted.size()):
		if str(actual_sorted[i]) != str(expected_sorted[i]):
			return false
	return true

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_INVENTORY_FLAG_FILTERS_UI_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

