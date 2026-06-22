extends SceneTree

const WindowScript := preload("res://scripts/ui/InventoryEquipmentWindow.gd")
const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const EquipmentDataServiceScript := preload("res://scripts/data/EquipmentDataService.gd")

var failures: Array[String] = []
var changed_data: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Socket UI", "ranger")
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player.get("inventory", {})), {
		"id": "frost_gem",
		"name": "寒霜宝石",
		"type": "gem",
		"amount": 1,
		"gem_id": "frost_gem",
	})
	var weapon_id := str(Dictionary(player.get("equipped_items", {})).get("weapon", ""))

	var window := WindowScript.new()
	root.add_child(window)
	await process_frame
	window.player_data_changed.connect(func(data: Dictionary): changed_data = data.duplicate(true))
	window.set_player_data(player)
	await process_frame

	window.select_item(weapon_id)
	await process_frame
	var before_detail := window.describe_item_for_test(weapon_id)
	_expect(before_detail.contains("宝石孔：0/2"), "equipment detail should show empty sockets")
	_expect(before_detail.contains("可镶嵌：寒霜宝石"), "equipment detail should show available socket gem")
	var action_button := window.find_child("EquipSelectedButton", true, false) as Button
	if action_button != null:
		_expect(not action_button.disabled, "equipped item with a gem should enable socket action")
		_expect(str(action_button.text) == "镶嵌", "equipped item action should become socket")
		action_button.pressed.emit()
		await process_frame

	_expect(not changed_data.is_empty(), "socket action should emit changed player data")
	var inventory: Dictionary = Dictionary(changed_data.get("inventory", {}))
	var weapon_entry: Dictionary = Dictionary(inventory.get(weapon_id, {}))
	var equipment: Dictionary = Dictionary(weapon_entry.get("equipment", {}))
	_expect(Array(equipment.get("socketed_gems", [])).has("frost_gem"), "weapon should store socketed frost gem")
	_expect(not inventory.has("frost_gem"), "socketed gem item should be consumed from inventory")
	var totals := EquipmentDataServiceScript.build_stat_totals(changed_data)
	_expect(int(totals.get("cold_damage", 0)) >= 6, "socketed frost gem should affect equipment totals")

	window.set_player_data(changed_data)
	await process_frame
	var after_detail := window.describe_item_for_test(weapon_id)
	_expect(after_detail.contains("宝石孔：1/2"), "equipment detail should show filled socket count")
	_expect(after_detail.contains("已镶嵌：寒霜宝石"), "equipment detail should list socketed gem")

	window.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_INVENTORY_GEM_SOCKET_UI_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
