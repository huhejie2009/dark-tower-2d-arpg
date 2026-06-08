extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var service := PlayerDataServiceScript.new()
	_expect(service.has_method("upgrade_basic_attack"), "PlayerDataService should expose basic attack upgrade")
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Skill Test", "warrior")
	player["skill_points"] = 2
	player["attack_damage"] = 30
	player["unlocked_skill_nodes"] = {}
	var result: Dictionary = service.call("upgrade_basic_attack", player) if service.has_method("upgrade_basic_attack") else {"ok": false, "player_data": player}
	_expect(bool(result.get("ok", false)), "basic attack upgrade should succeed when skill points are available")
	var upgraded: Dictionary = Dictionary(result.get("player_data", player))
	_expect(int(upgraded.get("skill_points", -1)) == 1, "basic attack upgrade should consume one skill point")
	_expect(int(upgraded.get("attack_damage", 0)) == 33, "basic attack upgrade should increase attack damage")
	var nodes: Dictionary = Dictionary(upgraded.get("unlocked_skill_nodes", {}))
	_expect(int(nodes.get("basic_attack_training", 0)) == 1, "basic attack training node should increase")
	var no_points := upgraded.duplicate(true)
	no_points["skill_points"] = 0
	var blocked: Dictionary = service.call("upgrade_basic_attack", no_points) if service.has_method("upgrade_basic_attack") else {"ok": false}
	_expect(not bool(blocked.get("ok", true)), "basic attack upgrade should fail without skill points")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_SKILL_POINT_BASIC_ATTACK_UPGRADE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
