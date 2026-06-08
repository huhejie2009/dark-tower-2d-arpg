extends SceneTree

const WindowScript := preload("res://scripts/ui/InventoryEquipmentWindow.gd")
const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Inventory Hint", "warrior")
	var inventory: Dictionary = Dictionary(player.get("inventory", {})).duplicate(true)
	inventory = InventoryDataServiceScript.add_item(inventory, _equipment_payload("better_sword", "Better Sword", "warrior", 6, {"attack_damage": 34}))
	inventory = InventoryDataServiceScript.add_item(inventory, _equipment_payload("ranger_bow", "Ranger Bow", "ranger", 8, {"attack_damage": 80}))
	player["inventory"] = inventory

	var window := WindowScript.new()
	root.add_child(window)
	await process_frame
	window.set_player_data(player)
	await process_frame

	_expect(window.has_method("get_item_action_hint_for_test"), "inventory should expose item action hint for tests")

	window.select_item("better_sword")
	await process_frame
	var detail := window.describe_item_for_test("better_sword")
	_expect(detail.contains("Action:"), "equipment detail should include action hint section")
	_expect(detail.contains("Can equip"), "upgrade detail should say it can be equipped")
	_expect(detail.contains("Equip +"), "upgrade detail should expose equip score delta")
	var equip_button := window.find_child("EquipSelectedButton", true, false) as Button
	if equip_button != null:
		_expect(not equip_button.disabled, "upgrade item equip button should be enabled")
		_expect(str(equip_button.text).contains("+"), "upgrade item button should show delta")

	window.select_item("ranger_bow")
	await process_frame
	var blocked_detail := window.describe_item_for_test("ranger_bow")
	_expect(blocked_detail.contains("Wrong class"), "blocked item detail should explain wrong class")
	if equip_button != null:
		_expect(equip_button.disabled, "wrong class item equip button should be disabled")
		_expect(str(equip_button.text) == "Class blocked", "wrong class button should explain block")

	window.queue_free()
	await process_frame
	_finish()

func _equipment_payload(id: String, item_name: String, pool: String, level: int, affixes: Dictionary) -> Dictionary:
	return {
		"id": id,
		"name": item_name,
		"type": "equipment",
		"amount": 1,
		"equipment": {
			"instance_id": id,
			"name": item_name,
			"slot": "weapon",
			"equipment_pool": pool,
			"item_level": level,
			"rarity": "magic",
			"affixes": affixes,
		},
	}

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_INVENTORY_EQUIPMENT_ACTION_HINTS_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
