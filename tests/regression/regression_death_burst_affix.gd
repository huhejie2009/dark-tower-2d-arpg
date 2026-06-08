extends SceneTree

const FloorRulesScript := preload("res://scripts/rules/FloorRules.gd")
const Enemy2DScript := preload("res://scripts/combat/Enemy2D.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var enemy := Enemy2DScript.new()
	enemy.apply_enemy_data(FloorRulesScript.get_enemy_type_data("rot_melee", 5, {"elite_affixes": ["death_burst"]}))
	host.add_child(enemy)
	await process_frame
	enemy.take_damage(99999)
	await process_frame
	_expect(host.find_child("DeathBurstArea", true, false) != null, "death burst elite should spawn burst area on death")
	host.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_DEATH_BURST_AFFIX_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
