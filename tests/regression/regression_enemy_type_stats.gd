extends SceneTree

const FloorRulesScript := preload("res://scripts/rules/FloorRules.gd")
const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")

var failures: Array[String] = []

func _init() -> void:
	var melee := FloorRulesScript.get_enemy_type_data("rot_melee", 3)
	var archer := FloorRulesScript.get_enemy_type_data("shadow_archer", 3)
	var guardian := FloorRulesScript.get_enemy_type_data("tower_guardian", 3)
	_expect(float(archer.get("attack_range", 0.0)) > float(melee.get("attack_range", 0.0)), "archer should outrange melee")
	_expect(int(guardian.get("max_health", 0)) > int(melee.get("max_health", 0)), "guardian should have more health than melee")
	_expect(float(guardian.get("move_speed", 999.0)) < float(melee.get("move_speed", 0.0)), "guardian should move slower than melee")

	var enemy := Enemy2DScript.new()
	_expect(enemy.has_method("apply_enemy_data"), "Enemy2D should expose apply_enemy_data")
	if enemy.has_method("apply_enemy_data"):
		enemy.call("apply_enemy_data", archer)
		_expect(str(enemy.get("enemy_type")) == "shadow_archer", "enemy type should apply")
		_expect(float(enemy.get("attack_range")) >= 190.0, "archer range should apply")
		_expect(bool(enemy.get("uses_projectile")), "archer should use projectile flag")
	enemy.free()
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_ENEMY_TYPE_STATS_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
