extends SceneTree

const AutoCombatControllerScript := preload("res://scripts/data/AutoCombatController.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var intent := AutoCombatControllerScript.build_intent(
		Vector2.ZERO,
		[{"position": Vector2(160, 0), "alive": true}],
		260.0
	)
	_expect(bool(intent.get("has_target", false)), "auto combat should find target")
	_expect(bool(intent.get("should_attack", false)), "target in range should attack")
	_expect(Vector2(intent.get("attack_direction", Vector2.ZERO)).dot(Vector2.RIGHT) > 0.9, "attack direction should face target")
	var far := AutoCombatControllerScript.build_intent(
		Vector2.ZERO,
		[{"position": Vector2(600, 0), "alive": true}],
		260.0
	)
	_expect(not bool(far.get("should_attack", true)), "far target should not attack")
	_expect(Vector2(far.get("move_vector", Vector2.ZERO)).dot(Vector2.RIGHT) > 0.9, "far target should move toward target")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_AUTO_COMBAT_CONTROLLER_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
