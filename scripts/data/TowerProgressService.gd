extends RefCounted
class_name TowerProgressService

static func build_floor_reward(floor: int) -> Dictionary:
	var safe_floor: int = maxi(1, floor)
	var reward := {
		"floor": safe_floor,
		"gold": 18 + safe_floor * 7,
		"crystal": 1 if safe_floor % 3 == 0 else 0,
	}
	if safe_floor % 5 == 0:
		reward["is_boss_floor"] = true
		reward["gold"] = int(reward["gold"]) + 45 + safe_floor * 4
		reward["crystal"] = maxi(1, int(reward["crystal"])) + int(safe_floor / 10)
		reward["guaranteed_magic_equipment"] = true
	else:
		reward["is_boss_floor"] = false
		reward["guaranteed_magic_equipment"] = false
	return reward

static func next_floor_after_clear(floor: int) -> int:
	return maxi(1, floor + 1)
