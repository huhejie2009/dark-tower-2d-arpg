extends SceneTree

const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")

const OUTPUT_PATH := "res://docs/qa/screenshots/town_stash_window_1280x720.png"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var player := SaveManagerScript.create_character("slot_1", "Stash QA", "warrior")
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player.get("inventory", {})), {
		"id": "qa_crystal",
		"name": "Crystal Shard",
		"type": "material",
		"amount": 12,
	})
	SaveManagerScript.save_active_player_data(player, 1)
	SaveManagerScript.save_active_stash({})
	var packed := load("res://scenes/Town.tscn")
	if not (packed is PackedScene):
		push_error("Town scene failed to load.")
		quit(1)
		return
	var town: Node = packed.instantiate()
	if town is Control:
		(town as Control).set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(town)
	for _i in range(8):
		await process_frame
	if town.has_method("trigger_town_facility_action_for_test"):
		town.call("trigger_town_facility_action_for_test", "stash", "open_stash")
	for _i in range(8):
		await process_frame
	RenderingServer.force_sync()
	var texture := root.get_texture()
	if texture == null:
		push_error("Stash screenshot texture is null.")
		quit(1)
		return
	var absolute_path := ProjectSettings.globalize_path(OUTPUT_PATH)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var error := texture.get_image().save_png(absolute_path)
	root.remove_child(town)
	town.queue_free()
	if error != OK:
		push_error("Failed to save stash screenshot: %s" % error_string(error))
		quit(1)
		return
	print("STASH_WINDOW_SCREENSHOT_SAVED %s" % absolute_path)
	quit(0)
