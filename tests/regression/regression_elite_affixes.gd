extends SceneTree

const FloorRulesScript := preload("res://scripts/rules/FloorRules.gd")
const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")

var failures: Array[String] = []

func _init() -> void:
	var base := FloorRulesScript.get_enemy_type_data("rot_melee", 5)
	var fast := FloorRulesScript.get_enemy_type_data("rot_melee", 5, {"elite_affixes": ["fast"]})
	var tough := FloorRulesScript.get_enemy_type_data("rot_melee", 5, {"elite_affixes": ["tough"]})
	var burst := FloorRulesScript.get_enemy_type_data("rot_melee", 5, {"elite_affixes": ["death_burst"]})
	_expect(float(fast.get("move_speed", 0.0)) > float(base.get("move_speed", 0.0)), "fast affix should increase move speed")
	_expect(int(tough.get("max_health", 0)) > int(base.get("max_health", 0)), "tough affix should increase max health")
	_expect(burst.get("death_burst", false) == true, "death_burst affix should enable death burst")
	_expect(int(burst.get("death_burst_damage", 0)) > 0, "death_burst should define damage")

	var enemy := Enemy2DScript.new()
	_expect(enemy.has_method("apply_enemy_data"), "Enemy2D should apply elite data")
	enemy.apply_enemy_data(burst)
	var applied_affixes: Variant = enemy.get("elite_affixes")
	_expect(applied_affixes is Array and applied_affixes.has("death_burst"), "Enemy2D should store elite affixes")
	_expect(enemy.get("death_burst") == true, "Enemy2D should store death burst flag")
	enemy.free()
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_ELITE_AFFIXES_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
