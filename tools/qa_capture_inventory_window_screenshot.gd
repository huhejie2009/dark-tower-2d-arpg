extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const InventoryEquipmentWindowScript := preload("res://scripts/ui/InventoryEquipmentWindow.gd")

const OUTPUT_PATH := "res://docs/qa/screenshots/inventory_equipment_window_1280x720.png"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Screenshot QA requires rendered Godot; run without --headless to avoid viewport capture hangs.")
		quit(2)
		return
	root.size = Vector2i(1280, 720)

	var background := ColorRect.new()
	background.name = "InventoryQaBackground"
	background.color = Color(0.018, 0.017, 0.018, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)

	var player := PlayerDataServiceScript.build_starter_player("slot_1", "背包验收", "warrior")
	player["inventory"] = _build_inventory(player)
	player["skill_points"] = 3

	var window := InventoryEquipmentWindowScript.new()
	root.add_child(window)
	window.set_player_data(player)
	window.visible = true
	if window.has_method("select_item"):
		window.call("select_item", "qa_rare_blade")

	for _i in range(12):
		await process_frame
	RenderingServer.force_sync()
	var texture := root.get_texture()
	if texture == null:
		push_error("Inventory screenshot texture is null.")
		quit(1)
		return
	var absolute_path := ProjectSettings.globalize_path(OUTPUT_PATH)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var error := texture.get_image().save_png(absolute_path)
	root.remove_child(window)
	root.remove_child(background)
	window.queue_free()
	background.queue_free()
	if error != OK:
		push_error("Failed to save inventory screenshot: %s" % error_string(error))
		quit(1)
		return
	print("INVENTORY_WINDOW_SCREENSHOT_SAVED %s" % absolute_path)
	quit(0)

func _build_inventory(player: Dictionary) -> Dictionary:
	var inventory := Dictionary(player.get("inventory", {}))
	inventory = InventoryDataServiceScript.add_item(inventory, _equipment_payload("qa_rare_blade", "裂塔长剑", "weapon", "rare", 9, {"attack_damage": 62}, true))
	inventory = InventoryDataServiceScript.add_item(inventory, _equipment_payload("qa_magic_armor", "霜铸胸甲", "armor", "magic", 6, {"max_health": 58}, false))
	inventory = InventoryDataServiceScript.add_item(inventory, _equipment_payload("qa_junk_gloves", "裂纹护手", "gloves", "common", 2, {"attack_damage": 3}, false, {"junk": true}))
	inventory = InventoryDataServiceScript.add_item(inventory, {
		"id": "qa_crystal_shard",
		"name": "水晶碎片",
		"type": "material",
		"amount": 18,
	})
	inventory = InventoryDataServiceScript.add_item(inventory, {
		"id": "qa_gold",
		"name": "金币",
		"type": "currency",
		"amount": 240,
	})
	return inventory

func _equipment_payload(id: String, item_name: String, slot: String, rarity: String, item_level: int, affixes: Dictionary, favorite: bool = false, flags: Dictionary = {}) -> Dictionary:
	var equipment := {
		"instance_id": id,
		"name": item_name,
		"slot": slot,
		"equipment_pool": "warrior",
		"item_level": item_level,
		"rarity": rarity,
		"affixes": affixes,
	}
	var binding_flags := {
		"locked": bool(flags.get("locked", false)),
		"favorite": bool(flags.get("favorite", favorite)),
		"junk": bool(flags.get("junk", false)),
		"sellable": bool(flags.get("sellable", true)),
	}
	return {
		"id": id,
		"name": item_name,
		"type": "equipment",
		"equipment": equipment,
		"binding_flags": binding_flags,
		"loot_quality": {
			"source": "elite",
			"quality_tag": "qa_visual",
			"item_level": item_level,
		},
	}
