extends SceneTree

const FloorRulesScript := preload("res://scripts/rules/FloorRules.gd")
const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var boss := Enemy2DScript.new()
	boss.apply_enemy_data(FloorRulesScript.get_enemy_type_data("tower_gatekeeper", 5, {"boss": true}))
	host.add_child(boss)
	await process_frame
	_expect(boss.has_method("trigger_boss_skill_for_test"), "Boss enemy should expose test skill trigger")
	if boss.has_method("trigger_boss_skill_for_test"):
		boss.call("trigger_boss_skill_for_test")
		await process_frame
		_expect(host.find_child("GatekeeperSlamWarning", true, false) != null, "gatekeeper skill should spawn warning visual")
		await create_timer(0.36).timeout
		_expect(host.find_child("GatekeeperSlamArea", true, false) != null, "gatekeeper skill should spawn slam area")
	host.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_GATEKEEPER_BOSS_SKILL_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
