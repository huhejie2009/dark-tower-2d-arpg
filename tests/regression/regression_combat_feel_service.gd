extends SceneTree

const CombatFeelServiceScript := preload("res://scripts/data/CombatFeelService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var warrior := CombatFeelServiceScript.get_basic_attack_feel("warrior_cleave")
	_expect(str(warrior.get("skill_id", "")) == "warrior_cleave", "feel profile should include skill id")
	_expect(float(warrior.get("windup", 0.0)) > 0.0, "feel profile should include windup")
	_expect(float(warrior.get("hit_frame", 0.0)) > float(warrior.get("windup", 0.0)), "hit frame should occur after windup")
	_expect(float(warrior.get("recovery", 0.0)) > 0.0, "feel profile should include recovery")
	_expect(float(warrior.get("input_buffer", 0.0)) > 0.0, "feel profile should include input buffer")
	_expect(float(warrior.get("cooldown", 0.0)) >= float(warrior.get("hit_frame", 0.0)), "cooldown should cover hit frame")
	_expect(str(warrior.get("animation_phase", "")) == "attack", "feel profile should expose animation phase")

	var ranger := CombatFeelServiceScript.get_basic_attack_feel("ranger_shot")
	_expect(float(ranger.get("cooldown", 0.0)) <= float(warrior.get("cooldown", 0.0)) + 0.15, "ranger basic should remain responsive")

	var unknown := CombatFeelServiceScript.get_basic_attack_feel("unknown_skill")
	_expect(str(unknown.get("skill_id", "")) == "unknown_skill", "unknown skill should still return a safe profile")
	_expect(float(unknown.get("cooldown", 0.0)) > 0.0, "unknown skill should have safe cooldown")

	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_COMBAT_FEEL_SERVICE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
