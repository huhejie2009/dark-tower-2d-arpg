extends SceneTree

const GameConstantsScript := preload("res://scripts/app/GameConstants.gd")
const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := SaveManagerScript.create_character("slot_1", "2.5D UI", "warrior")
	player["current_exp"] = 35
	player["exp_to_next_level"] = 100
	player["skill_points"] = 2
	SaveManagerScript.save_active_player_data(player, 4)

	var packed := load(GameConstantsScript.ACTIVE_GAME_SCENE)
	_expect(packed is PackedScene, "active 2.5D game scene should load")
	if not packed is PackedScene:
		_finish()
		return

	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame

	_expect(scene.has_method("build_hud_inventory_pause_snapshot_for_test"), "2.5D runtime should expose HUD/inventory/pause snapshot")
	_expect(scene.has_method("_toggle_inventory_window_for_test"), "2.5D runtime should expose inventory toggle test hook")
	_expect(scene.has_method("_toggle_pause_for_test"), "2.5D runtime should expose pause toggle test hook")
	_expect(scene.has_method("_handle_cancel_for_test"), "2.5D runtime should expose cancel handling test hook")
	if not scene.has_method("build_hud_inventory_pause_snapshot_for_test"):
		scene.queue_free()
		await process_frame
		_finish()
		return

	var initial: Dictionary = scene.call("build_hud_inventory_pause_snapshot_for_test")
	_expect(bool(initial.get("has_hud", false)), "2.5D runtime should create shared HUD")
	_expect(bool(initial.get("has_inventory_window", false)), "2.5D runtime should create shared inventory window")
	_expect(bool(initial.get("has_pause_overlay", false)), "2.5D runtime should create pause overlay")
	_expect(str(initial.get("hud_status_text", "")).contains("Floor"), "HUD should show floor status")
	_expect(str(initial.get("hud_inventory_text", "")).contains("Bag"), "HUD should show bag capacity")
	_expect(int(initial.get("hud_level", 0)) >= 1, "HUD should expose player level")
	_expect(not bool(initial.get("tree_paused", true)), "2.5D runtime should start unpaused")

	scene.call("_toggle_inventory_window_for_test")
	await process_frame
	var inventory_open: Dictionary = scene.call("build_hud_inventory_pause_snapshot_for_test")
	_expect(bool(inventory_open.get("inventory_visible", false)), "opening inventory should show inventory window")
	_expect(bool(inventory_open.get("tree_paused", false)), "opening inventory should pause combat")
	_expect(bool(inventory_open.get("menu_blocks_combat", false)), "inventory should block combat input")

	scene.call("_handle_cancel_for_test")
	await process_frame
	var after_cancel_inventory: Dictionary = scene.call("build_hud_inventory_pause_snapshot_for_test")
	_expect(not bool(after_cancel_inventory.get("inventory_visible", true)), "cancel should close inventory first")
	_expect(not bool(after_cancel_inventory.get("tree_paused", true)), "closing inventory should resume when pause overlay is closed")

	scene.call("_toggle_pause_for_test")
	await process_frame
	var pause_open: Dictionary = scene.call("build_hud_inventory_pause_snapshot_for_test")
	_expect(bool(pause_open.get("pause_visible", false)), "pause toggle should show pause overlay")
	_expect(bool(pause_open.get("tree_paused", false)), "pause overlay should pause combat")
	_expect(str(pause_open.get("pause_focus_name", "")) == "ResumeButton", "pause overlay should focus resume button")

	scene.call("_toggle_inventory_window_for_test")
	await process_frame
	var pause_inventory_open: Dictionary = scene.call("build_hud_inventory_pause_snapshot_for_test")
	_expect(bool(pause_inventory_open.get("pause_visible", false)), "opening inventory from pause should keep pause overlay available")
	_expect(bool(pause_inventory_open.get("inventory_visible", false)), "inventory should open while paused")
	_expect(bool(pause_inventory_open.get("tree_paused", false)), "pause should remain active while inventory is open")

	scene.call("_handle_cancel_for_test")
	await process_frame
	var after_cancel_paused_inventory: Dictionary = scene.call("build_hud_inventory_pause_snapshot_for_test")
	_expect(bool(after_cancel_paused_inventory.get("pause_visible", false)), "cancel should return focus to pause overlay after closing inventory")
	_expect(not bool(after_cancel_paused_inventory.get("inventory_visible", true)), "cancel should close inventory under pause overlay")
	_expect(bool(after_cancel_paused_inventory.get("tree_paused", false)), "pause overlay should keep the tree paused after inventory closes")

	scene.call("_handle_cancel_for_test")
	await process_frame
	var after_cancel_pause: Dictionary = scene.call("build_hud_inventory_pause_snapshot_for_test")
	_expect(not bool(after_cancel_pause.get("pause_visible", true)), "second cancel should close pause overlay")
	_expect(not bool(after_cancel_pause.get("tree_paused", true)), "closing pause overlay should resume combat")

	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	root.get_tree().paused = false
	if failures.is_empty():
		print("NEW_PROJECT_PROTOTYPE_2_5D_HUD_INVENTORY_PAUSE_BRIDGE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
