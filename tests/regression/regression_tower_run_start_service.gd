extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const TowerRunStartServiceScript := preload("res://scripts/data/TowerRunStartService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Runner", "warrior")
	player["highest_floor"] = 42

	var options: Dictionary = TowerRunStartServiceScript.build_start_options(player)
	_expect(int(options.get("fresh_floor", 0)) == 1, "fresh run should start from floor 1")
	_expect(int(options.get("best_floor", 0)) == 42, "best run should expose saved best floor")
	_expect(str(options.get("fresh_label", "")).contains("Floor 1"), "fresh label should be readable")
	_expect(str(options.get("best_label", "")).contains("42"), "best label should include best floor")

	TowerRunStartServiceScript.request_start_floor(42)
	_expect(int(TowerRunStartServiceScript.consume_start_floor(player)) == 42, "requested best floor should be consumed once")
	_expect(int(TowerRunStartServiceScript.consume_start_floor(player)) == 1, "missing request should default to a fresh floor 1 run")

	TowerRunStartServiceScript.request_start_floor(999)
	_expect(int(TowerRunStartServiceScript.consume_start_floor(player)) == 42, "requested floor should clamp to saved best floor")

	TowerRunStartServiceScript.request_start_floor(-5)
	_expect(int(TowerRunStartServiceScript.consume_start_floor(player)) == 1, "requested floor should clamp to floor 1 minimum")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_TOWER_RUN_START_SERVICE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
