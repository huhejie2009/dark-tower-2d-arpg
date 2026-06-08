extends SceneTree

const FloorRulesScript := preload("res://scripts/rules/FloorRules.gd")

var failures: Array[String] = []

func _init() -> void:
	var expected_templates := ["standard_clear", "dense_room", "ranged_pressure", "guardian_mix", "elite_preview", "boss_gatekeeper"]
	var seen := {}
	for floor in range(1, 16):
		var template: Dictionary = FloorRulesScript.build_floor_template(floor)
		seen[str(template.get("template_id", ""))] = true
		_expect(str(template.get("template_id", "")) != "", "floor %d should have template id" % floor)
		_expect(Array(template.get("enemies", [])).size() > 0, "floor %d should spawn enemies" % floor)
		for spawn in Array(template.get("enemies", [])):
			var enemy_type := str(Dictionary(spawn).get("enemy_type", ""))
			_expect(["rot_melee", "shadow_archer", "tower_guardian", "tower_gatekeeper"].has(enemy_type), "enemy type should be known: %s" % enemy_type)
	for template_id in expected_templates:
		_expect(seen.has(template_id), "fifteen floors should include template %s" % template_id)
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_FLOOR_TEMPLATES_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
