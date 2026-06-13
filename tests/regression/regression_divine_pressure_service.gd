extends SceneTree

const DivinePressureServiceScript := preload("res://scripts/data/DivinePressureService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var config := DivinePressureServiceScript.build_event_config("elite_defeated", 4)
	_expect(str(config.get("trigger", "")) == "elite_defeated", "trigger should be preserved")
	_expect(float(config.get("warning_seconds", 0.0)) >= 0.6, "warning should be at least 0.6 seconds")
	_expect(float(config.get("radius", 0.0)) >= 80.0, "pressure radius should be readable")
	_expect(int(config.get("damage", 0)) > 0, "pressure damage should be positive")
	_expect(not bool(config.get("blocks_portal", true)), "minimal pressure should not block portal yet")
	_expect(DivinePressureServiceScript.should_trigger_after_enemy({"is_elite": true}, false), "elite death can trigger pressure")
	_expect(not DivinePressureServiceScript.should_trigger_after_enemy({"is_elite": false}, false), "normal death should not trigger pressure")
	_expect(not DivinePressureServiceScript.should_trigger_after_enemy({"is_boss": true}, true), "do not trigger when a pressure event is already active")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_DIVINE_PRESSURE_SERVICE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
