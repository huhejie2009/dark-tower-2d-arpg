extends SceneTree

const DamageFeedbackServiceScript := preload("res://scripts/data/DamageFeedbackService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var normal := DamageFeedbackServiceScript.build_damage_feedback("enemy_normal", 12, 60, Vector2.RIGHT)
	_expect(str(normal.get("target_kind", "")) == "enemy_normal", "feedback should preserve target kind")
	_expect(int(normal.get("amount", 0)) == 12, "feedback should preserve damage amount")
	_expect(float(normal.get("stagger_duration", 0.0)) > 0.0, "normal enemy should receive stagger")
	_expect(float(normal.get("knockback_distance", 0.0)) > 0.0, "normal enemy should receive knockback")
	_expect(float(normal.get("hit_flash_duration", 0.0)) > 0.0, "feedback should expose hit flash duration")
	_expect(str(normal.get("vfx_event", "")) == "hit_impact", "feedback should expose VFX event id")
	_expect(str(normal.get("audio_event", "")) != "", "feedback should expose audio event id")
	_expect(bool(normal.get("damage_number", false)), "feedback should request damage number")

	var boss := DamageFeedbackServiceScript.build_damage_feedback("enemy_boss", 12, 400, Vector2.RIGHT)
	_expect(float(boss.get("knockback_distance", 99.0)) < float(normal.get("knockback_distance", 0.0)), "boss should resist knockback")
	_expect(float(boss.get("stagger_duration", 99.0)) <= float(normal.get("stagger_duration", 0.0)), "boss should resist stagger")

	var lethal := DamageFeedbackServiceScript.build_damage_feedback("player", 999, 120, Vector2.LEFT)
	_expect(str(lethal.get("impact_level", "")) == "lethal", "lethal hit should be classified")
	_expect(float(lethal.get("camera_shake", 0.0)) > 0.0, "player hit should expose camera shake intensity")

	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_DAMAGE_FEEDBACK_SERVICE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
