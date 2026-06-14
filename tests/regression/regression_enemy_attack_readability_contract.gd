extends SceneTree

const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var enemy := Enemy2DScript.new()
	root.add_child(enemy)
	await process_frame
	_expect(enemy.has_method("get_attack_readability_snapshot_for_test"), "Enemy should expose attack readability snapshot")
	var snapshot: Dictionary = enemy.call("get_attack_readability_snapshot_for_test") if enemy.has_method("get_attack_readability_snapshot_for_test") else {}
	_expect(float(snapshot.get("minimum_attack_warning_seconds", 0.0)) >= 0.1, "enemy warning baseline should exist")
	_expect(Array(snapshot.get("required_animation_states", [])).has("attack"), "attack animation state should be required")
	_expect(bool(snapshot.get("separate_hit_vfx", false)), "hit VFX should remain separate from body sprite")
	enemy.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_ENEMY_ATTACK_READABILITY_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
