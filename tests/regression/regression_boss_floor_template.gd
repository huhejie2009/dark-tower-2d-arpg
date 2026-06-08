extends SceneTree

const FloorRulesScript := preload("res://scripts/rules/FloorRules.gd")

var failures: Array[String] = []

func _init() -> void:
	var template := FloorRulesScript.build_floor_template(5)
	_expect(str(template.get("template_id", "")) == "boss_gatekeeper", "floor 5 should be boss gatekeeper template")
	var enemies: Array = Array(template.get("enemies", []))
	_expect(enemies.size() >= 1, "boss floor should spawn at least one enemy")
	var has_boss := false
	for spawn in enemies:
		var data: Dictionary = Dictionary(spawn)
		if str(data.get("enemy_type", "")) == "tower_gatekeeper":
			has_boss = true
			_expect(Dictionary(data.get("modifiers", {})).get("boss", false) == true, "gatekeeper spawn should be marked boss")
	var boss_data := FloorRulesScript.get_enemy_type_data("tower_gatekeeper", 5, {"boss": true})
	_expect(boss_data.get("is_boss", false) == true, "gatekeeper data should be boss")
	_expect(int(boss_data.get("max_health", 0)) >= 220, "gatekeeper should have boss health")
	_expect(has_boss, "boss floor should include tower_gatekeeper")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_BOSS_FLOOR_TEMPLATE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
