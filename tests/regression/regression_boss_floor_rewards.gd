extends SceneTree

const TowerProgressServiceScript := preload("res://scripts/data/TowerProgressService.gd")

var failures: Array[String] = []

func _init() -> void:
	var floor_4 := TowerProgressServiceScript.build_floor_reward(4)
	var floor_5 := TowerProgressServiceScript.build_floor_reward(5)
	_expect(floor_5.get("is_boss_floor", false) == true, "floor 5 reward should be marked boss floor")
	_expect(int(floor_5.get("gold", 0)) > int(floor_4.get("gold", 0)), "boss floor should give more gold than previous floor")
	_expect(int(floor_5.get("crystal", 0)) >= 1, "boss floor should give at least one crystal")
	_expect(floor_5.get("guaranteed_magic_equipment", false) == true, "boss floor should mark guaranteed magic equipment")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_BOSS_FLOOR_REWARDS_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
