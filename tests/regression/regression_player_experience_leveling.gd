extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var service := PlayerDataServiceScript.new()
	_expect(service.has_method("add_experience"), "PlayerDataService should expose add_experience")
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "XP Test", "warrior")
	player["current_exp"] = 90
	player["exp_to_next_level"] = 100
	player["skill_points"] = 0
	player["max_health"] = 120
	player["health"] = 80
	player["attack_damage"] = 24
	var result: Dictionary = service.call("add_experience", player, 35) if service.has_method("add_experience") else player
	_expect(int(result.get("player_level", 0)) == 2, "experience should level player up")
	_expect(int(result.get("current_exp", -1)) == 25, "experience should carry overflow after leveling")
	_expect(int(result.get("exp_to_next_level", 0)) > 100, "next level requirement should increase")
	_expect(int(result.get("skill_points", -1)) == 1, "level up should grant a skill point")
	_expect(int(result.get("max_health", 0)) > 120, "level up should increase max health")
	_expect(int(result.get("health", 0)) > 80, "level up should add current health with max health growth")
	_expect(int(result.get("attack_damage", 0)) > 24, "level up should increase attack damage")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_PLAYER_EXPERIENCE_LEVELING_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
