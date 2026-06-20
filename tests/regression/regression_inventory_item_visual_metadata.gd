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
		"item_level": 4,
		"rarity": "magic",
		"affixes": {"attack_damage": 28},
	}
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player["inventory"]), {
		"id": "better_weapon",
		"name": "Better Sword",
		"type": "equipment",
		"equipment": better_weapon,
	})
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player["inventory"]), {
		"id": "gold",
		"name": "金币",
		"type": "currency",
		"amount": 240,
	})
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player["inventory"]), {
		"id": "crystal_shard",
		"name": "水晶碎片",
		"type": "material",
		"amount": 18,
	})

	var window := InventoryEquipmentWindowScript.new()
	root.add_child(window)
	window.set_player_data(player)
	await process_frame

	_expect(window.has_method("get_item_visual_metadata_for_test"), "window should expose item visual metadata")
	if window.has_method("get_item_visual_metadata_for_test"):
		var equipped_meta: Dictionary = Dictionary(window.call("get_item_visual_metadata_for_test", starter_weapon_id))
		_expect(bool(equipped_meta.get("equipped", false)), "equipped item metadata should mark equipped")
		_expect(str(equipped_meta.get("badge", "")) == "E", "equipped item should use E badge")

		var better_meta: Dictionary = Dictionary(window.call("get_item_visual_metadata_for_test", "better_weapon"))
		_expect(str(better_meta.get("rarity", "")) == "magic", "metadata should include rarity")
		_expect(str(better_meta.get("badge", "")) == "+", "stronger equipment should use upgrade badge")
		_expect(bool(better_meta.get("upgrade", false)), "better item should be marked as upgrade")
		_expect(str(better_meta.get("border_color", "")) != "", "metadata should expose rarity border color")
		_expect(str(better_meta.get("label", "")).contains("武器"), "equipment label should include localized slot label")
		_expect(not str(better_meta.get("label", "")).contains("WEA"), "equipment label should not use English slot abbreviation")

		var gold_meta: Dictionary = Dictionary(window.call("get_item_visual_metadata_for_test", "gold"))
		var crystal_meta: Dictionary = Dictionary(window.call("get_item_visual_metadata_for_test", "crystal_shard"))
		_expect(str(gold_meta.get("label", "")).contains("金"), "currency label should show a localized item hint")
		_expect(str(gold_meta.get("label", "")).contains("240"), "currency label should include stack amount")
		_expect(str(crystal_meta.get("label", "")).contains("晶"), "material label should show a localized item hint")
		_expect(str(crystal_meta.get("label", "")).contains("18"), "material label should include stack amount")

	window.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_INVENTORY_ITEM_VISUAL_METADATA_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
