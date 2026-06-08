extends SceneTree

const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")
const TowerRunStartServiceScript := preload("res://scripts/data/TowerRunStartService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := SaveManagerScript.create_character("slot_1", "Start Options", "warrior")
	player["highest_floor"] = 37
	SaveManagerScript.save_active_player_data(player, 37)

	var town_packed := load("res://scenes/Town.tscn")
	_expect(town_packed is PackedScene, "Town should load")
	if town_packed is PackedScene:
		var town: Node = town_packed.instantiate()
		root.add_child(town)
		await process_frame
		var fresh_button := town.find_child("EnterTowerButton", true, false) as Button
		var best_button := town.find_child("EnterBestFloorButton", true, false) as Button
		_expect(fresh_button != null, "town should keep the main enter tower button")
		_expect(best_button != null, "town should expose best floor challenge button")
		if fresh_button != null:
			_expect(str(fresh_button.text).contains("Floor 1"), "main enter tower button should start a fresh floor 1 run")
		if best_button != null:
			_expect(str(best_button.text).contains("37"), "best floor button should show saved best floor")
		town.queue_free()
		await process_frame

	TowerRunStartServiceScript.request_start_floor(37)
	var game_packed := load("res://scenes/Game2D.tscn")
	_expect(game_packed is PackedScene, "Game2D should load")
	if game_packed is PackedScene:
		var game: Node = game_packed.instantiate()
		root.add_child(game)
		await process_frame
		_expect(int(game.get("current_floor")) == 37, "Game2D should honor requested best floor")
		game.queue_free()
		await process_frame

	var fresh_game: Node = game_packed.instantiate()
	root.add_child(fresh_game)
	await process_frame
	_expect(int(fresh_game.get("current_floor")) == 1, "Game2D should default to fresh floor 1 when no request exists")
	fresh_game.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_TOWN_TOWER_START_OPTIONS_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
