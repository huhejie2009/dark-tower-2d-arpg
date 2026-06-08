extends SceneTree

const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")
const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := SaveManagerScript.create_character("slot_1", "Prep Panel", "warrior")
	player["player_level"] = 5
	player["skill_points"] = 2
	player["highest_floor"] = 9
	player["inventory"] = InventoryDataServiceScript.add_item(Dictionary(player.get("inventory", {})), {
		"id": "gold",
		"name": "Gold",
		"type": "currency",
		"amount": 55,
	})
	SaveManagerScript.save_active_player_data(player, 9)

	var packed := load("res://scenes/Town.tscn")
	_expect(packed is PackedScene, "Town should load")
	if packed is PackedScene:
		var town: Node = packed.instantiate()
		root.add_child(town)
		await process_frame
		_expect(town.find_child("TownPrepPanel", true, false) != null, "town should expose a prep panel")
		_expect(town.find_child("TownCharacterSummary", true, false) != null, "prep panel should show character summary")
		_expect(town.find_child("TownProgressSummary", true, false) != null, "prep panel should show tower progress")
		_expect(town.find_child("TownResourceSummary", true, false) != null, "prep panel should show resources")
		_expect(town.find_child("TownGrowthSummary", true, false) != null, "prep panel should show growth")
		_expect(town.find_child("TownStartSummary", true, false) != null, "prep panel should show start options")
		var character := town.find_child("TownCharacterSummary", true, false) as Label
		var progress := town.find_child("TownProgressSummary", true, false) as Label
		var resources := town.find_child("TownResourceSummary", true, false) as Label
		var growth := town.find_child("TownGrowthSummary", true, false) as Label
		var start := town.find_child("TownStartSummary", true, false) as Label
		if character != null:
			_expect(str(character.text).contains("Prep Panel"), "character summary should include character name")
		if progress != null:
			_expect(str(progress.text).contains("Best Floor 9"), "progress summary should include best floor")
		if resources != null:
			_expect(str(resources.text).contains("Gold 55"), "resource summary should include gold")
		if growth != null:
			_expect(str(growth.text).contains("SP 2"), "growth summary should include skill points")
		if start != null:
			_expect(str(start.text).contains("Floor 1") and str(start.text).contains("9"), "start summary should explain both start options")
		town.queue_free()
		await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_TOWN_PREP_PANEL_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
