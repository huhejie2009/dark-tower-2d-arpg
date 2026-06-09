extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const InventoryEquipmentWindowScript := preload("res://scripts/ui/InventoryEquipmentWindow.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Junk Confirm", "warrior")
	var inventory: Dictionary = Dictionary(player.get("inventory", {}))
	inventory = InventoryDataServiceScript.add_item(inventory, _equipment_payload("junk_sword", "Junk Sword", "weapon", {"junk": true}))
	inventory = InventoryDataServiceScript.add_item(inventory, _equipment_payload("locked_junk", "Locked Junk", "armor", {"junk": true, "locked": true}))
	player["inventory"] = inventory

	var window := InventoryEquipmentWindowScript.new()
	root.add_child(window)
	window.set_player_data(player)
	await process_frame

	_expect(window.find_child("JunkActionConfirmDialog", true, false) != null, "inventory should expose a junk action confirmation dialog")
	_expect(window.has_method("get_pending_junk_action_preview_for_test"), "inventory should expose pending junk action preview for tests and future UI")
	_expect(window.has_method("confirm_pending_junk_action_for_test"), "inventory should expose confirmation hook for tests and future dialog integration")

	if window.has_method("sell_junk_items") and window.has_method("get_pending_junk_action_preview_for_test"):
		window.call("sell_junk_items")
		var pending_preview: Dictionary = Dictionary(window.call("get_pending_junk_action_preview_for_test"))
		var unchanged_inventory: Dictionary = Dictionary(Dictionary(window.get("player_data")).get("inventory", {}))
		_expect(unchanged_inventory.has("junk_sword"), "opening sell junk confirmation should not immediately remove items")
		_expect(str(pending_preview.get("mode", "")) == "sell", "pending preview should remember sell mode")
		_expect(int(pending_preview.get("processed_count", 0)) == 1, "pending preview should include process count")
		_expect(int(pending_preview.get("protected_count", 0)) == 1, "pending preview should include protected count")
		_expect(str(pending_preview.get("confirm_text", "")).contains("Protected 1"), "confirm text should show protected item count")
		_expect(str(pending_preview.get("confirm_text", "")).contains("Gold"), "sell confirm text should show gold reward")

	if window.has_method("confirm_pending_junk_action_for_test"):
		window.call("confirm_pending_junk_action_for_test")
		var updated_inventory: Dictionary = Dictionary(Dictionary(window.get("player_data")).get("inventory", {}))
		_expect(not updated_inventory.has("junk_sword"), "confirming pending junk action should remove unprotected junk")
		_expect(updated_inventory.has("locked_junk"), "confirming pending junk action should keep protected junk")
		_expect(updated_inventory.has("gold"), "confirming sell junk should add gold")

	window.queue_free()
	await process_frame
	_finish()

func _equipment_payload(id: String, item_name: String, slot: String, flags: Dictionary) -> Dictionary:
	return {
		"id": id,
		"name": item_name,
		"type": "equipment",
		"binding_flags": flags,
		"equipment": {
			"instance_id": id,
			"name": item_name,
			"slot": slot,
			"equipment_pool": "warrior",
			"item_level": 2,
			"rarity": "magic",
			"affixes": {"attack_damage": 2},
		},
	}

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_INVENTORY_JUNK_ACTION_CONFIRMATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
