extends SceneTree

const LootQualityServiceScript := preload("res://scripts/data/LootQualityService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var floor_1 := LootQualityServiceScript.build_quality_profile(1, "normal", 1)
	var floor_8 := LootQualityServiceScript.build_quality_profile(8, "normal", 1)
	var elite := LootQualityServiceScript.build_quality_profile(8, "elite", 1)
	var boss := LootQualityServiceScript.build_quality_profile(10, "boss", 1)

	_expect(int(floor_8.get("item_level", 0)) > int(floor_1.get("item_level", 0)), "item level should scale with floor")
	_expect(float(floor_8.get("equipment_chance", 0.0)) >= float(floor_1.get("equipment_chance", 0.0)), "equipment chance should not decrease with floor")
	_expect(float(elite.get("rare_chance", 0.0)) > float(floor_8.get("rare_chance", 0.0)), "elite source should improve rare chance")
	_expect(bool(boss.get("guaranteed_equipment", false)), "boss source should guarantee equipment")
	_expect(float(boss.get("legendary_chance", 0.0)) > float(elite.get("legendary_chance", 0.0)), "boss should have stronger legendary chance")
	_expect(str(boss.get("source", "")) == "boss", "profile should keep source")
	_expect(str(boss.get("quality_tag", "")) != "", "profile should expose readable quality tag")

	var normal_roll := LootQualityServiceScript.choose_drop_kind(floor_1, 1)
	var equipment_roll := LootQualityServiceScript.choose_drop_kind(floor_8, 3)
	var boss_roll := LootQualityServiceScript.choose_drop_kind(boss, 2)
	_expect(["currency", "material", "equipment"].has(normal_roll), "drop kind should be known")
	_expect(equipment_roll == "equipment", "third kill should still support equipment cadence")
	_expect(boss_roll == "equipment", "boss drop kind should be equipment")

	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_LOOT_QUALITY_SERVICE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
