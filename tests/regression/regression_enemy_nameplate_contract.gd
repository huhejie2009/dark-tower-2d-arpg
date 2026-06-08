extends SceneTree

const FloorRulesScript := preload("res://scripts/rules/FloorRules.gd")
const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var host := Node2D.new()
	root.add_child(host)

	var elite := Enemy2DScript.new()
	elite.apply_enemy_data(FloorRulesScript.get_enemy_type_data("tower_guardian", 6, {"elite_affixes": ["tough", "death_burst"]}))
	host.add_child(elite)
	await process_frame
	var elite_nameplate := elite.find_child("EnemyNameplate", true, false)
	_expect(elite_nameplate != null, "elite should create nameplate")
	_expect(str(elite.get("nameplate_text")).contains("Elite"), "elite nameplate text should include rank")
	_expect(str(elite.get("nameplate_text")).contains("tough"), "elite nameplate should include affix")
	_expect(str(elite.get("nameplate_text")).contains("death_burst"), "elite nameplate should include death burst affix")

	var boss := Enemy2DScript.new()
	boss.apply_enemy_data(FloorRulesScript.get_enemy_type_data("tower_gatekeeper", 5, {"boss": true}))
	host.add_child(boss)
	await process_frame
	var boss_nameplate := boss.find_child("EnemyNameplate", true, false)
	_expect(boss_nameplate != null, "boss should create nameplate")
	_expect(str(boss.get("nameplate_text")).contains("Boss"), "boss nameplate text should include boss rank")
	_expect(str(boss.get("nameplate_text")).contains("Tower Gatekeeper"), "boss nameplate should include name")
	_expect(str(boss.get("nameplate_text")).contains("short_charge"), "boss nameplate should include boss skill")

	host.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_ENEMY_NAMEPLATE_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
