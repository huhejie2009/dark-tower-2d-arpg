extends SceneTree

const FloorRulesScript := preload("res://scripts/rules/FloorRules.gd")
const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var boss_data := FloorRulesScript.get_enemy_type_data("tower_gatekeeper", 5, {"boss": true})
	_expect(Array(boss_data.get("boss_skills", [])).has("short_charge"), "gatekeeper data should include short_charge")

	var host := Node2D.new()
	root.add_child(host)
	var boss := Enemy2DScript.new()
	boss.apply_enemy_data(boss_data)
	boss.global_position = Vector2.ZERO
	host.add_child(boss)
	await process_frame
	_expect(boss.has_method("trigger_boss_charge_for_test"), "Boss enemy should expose charge trigger")
	if boss.has_method("trigger_boss_charge_for_test"):
		boss.call("trigger_boss_charge_for_test")
		await process_frame
		_expect(host.find_child("GatekeeperChargeWarning", true, false) != null, "charge should spawn warning")
		await _wait_for_child(host, "GatekeeperChargeArea", 45)
		_expect(host.find_child("GatekeeperChargeArea", true, false) != null, "charge should spawn damage area")
		_expect(boss.global_position.x > 40.0, "charge should move boss forward")
	host.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_GATEKEEPER_CHARGE_SKILL_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _wait_for_child(root_node: Node, child_name: String, max_frames: int) -> void:
	for _i in range(max_frames):
		if root_node.find_child(child_name, true, false) != null:
			return
		await process_frame
