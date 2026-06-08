extends SceneTree

const EnemyBehaviorServiceScript := preload("res://scripts/data/EnemyBehaviorService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var melee := EnemyBehaviorServiceScript.get_behavior_profile("rot_melee")
	var archer := EnemyBehaviorServiceScript.get_behavior_profile("shadow_archer")
	var guardian := EnemyBehaviorServiceScript.get_behavior_profile("tower_guardian")
	var boss := EnemyBehaviorServiceScript.get_behavior_profile("tower_gatekeeper")

	_expect(str(melee.get("archetype", "")) == "melee_rusher", "rot melee should use melee rusher archetype")
	_expect(str(archer.get("archetype", "")) == "ranged_kiter", "shadow archer should use ranged kiter archetype")
	_expect(float(archer.get("preferred_distance", 0.0)) > float(melee.get("preferred_distance", 0.0)), "archer should prefer longer distance")
	_expect(float(archer.get("retreat_distance", 0.0)) > 0.0, "archer should expose retreat distance")
	_expect(float(guardian.get("commit_distance", 0.0)) > float(melee.get("commit_distance", 0.0)), "guardian should commit from farther away")
	_expect(float(boss.get("attack_windup", 0.0)) >= float(guardian.get("attack_windup", 0.0)), "boss should keep readable attack windup")

	var far_archer := EnemyBehaviorServiceScript.evaluate_intent(archer, 260.0, Vector2.RIGHT)
	_expect(str(far_archer.get("intent", "")) == "approach", "far archer should approach into preferred range")
	var close_archer := EnemyBehaviorServiceScript.evaluate_intent(archer, 70.0, Vector2.RIGHT)
	_expect(str(close_archer.get("intent", "")) == "retreat", "close archer should retreat")
	var ready_archer := EnemyBehaviorServiceScript.evaluate_intent(archer, 180.0, Vector2.RIGHT)
	_expect(str(ready_archer.get("intent", "")) == "attack", "archer in band should attack")
	_expect(float(ready_archer.get("attack_windup", 0.0)) > 0.0, "attack intent should include windup")

	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_ENEMY_BEHAVIOR_SERVICE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
