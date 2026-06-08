extends SceneTree

const LootRulesScript := preload("res://scripts/rules/LootRules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var normal_drop: Dictionary = LootRulesScript.generate_enemy_drop(3, "warrior", 3)
	_expect(Dictionary(normal_drop.get("loot_quality", {})).has("item_level"), "legacy enemy drop should include loot quality metadata")
	_expect(str(normal_drop.get("source", "normal")) == "normal", "legacy enemy drop should default to normal source")

	var elite_drop: Dictionary = LootRulesScript.generate_enemy_drop_with_source(8, "warrior", 3, "elite")
	var quality: Dictionary = Dictionary(elite_drop.get("loot_quality", {}))
	_expect(str(elite_drop.get("source", "")) == "elite", "elite drop should preserve source")
	_expect(int(quality.get("item_level", 0)) >= 8, "elite drop should use floor-scaled item level")
	if str(elite_drop.get("type", "")) == "equipment":
		var equipment: Dictionary = Dictionary(elite_drop.get("equipment", {}))
		_expect(int(equipment.get("item_level", 0)) >= int(quality.get("item_level", 0)), "equipment should receive quality item level")
		_expect(["magic", "rare", "legendary"].has(str(equipment.get("rarity", ""))), "elite equipment should avoid common rarity")

	var boss_drop := LootRulesScript.generate_boss_clear_reward(10, "warrior")
	var boss_quality: Dictionary = Dictionary(boss_drop.get("loot_quality", {}))
	_expect(str(boss_drop.get("source", "")) == "boss", "boss reward should preserve boss source")
	_expect(bool(boss_quality.get("guaranteed_equipment", false)), "boss reward should carry guaranteed equipment metadata")
	_expect(["rare", "legendary"].has(str(Dictionary(boss_drop.get("equipment", {})).get("rarity", ""))), "floor 10 boss reward should be rare or better")

	var sample: Dictionary = LootRulesScript.sample_floor_loot_quality_for_test(8, "warrior", 12, "elite")
	_expect(int(sample.get("equipment_count", 0)) > 0, "sample should count equipment drops")
	_expect(int(sample.get("highest_item_level", 0)) >= 8, "sample should report floor-scaled highest item level")
	_expect(int(sample.get("rare_or_better_count", 0)) > 0, "elite sample should include rare-or-better drops")

	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_LOOT_QUALITY_RULES_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
