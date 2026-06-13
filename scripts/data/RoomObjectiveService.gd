extends RefCounted
class_name RoomObjectiveService

static func build_state(template: Dictionary) -> Dictionary:
	var objective_id := str(template.get("objective", "clear_all"))
	var enemies: Array = Array(template.get("enemies", []))
	var target_count := _count_targets(objective_id, enemies)
	var state := {
		"objective_id": objective_id,
		"template_id": str(template.get("template_id", "standard_clear")),
		"floor": int(template.get("floor", 1)),
		"target_count": maxi(1, target_count),
		"current_count": 0,
		"completed": false,
	}
	state["hud_text"] = build_hud_text(state)
	return state

static func record_enemy_defeated(state: Dictionary, enemy_data: Dictionary) -> Dictionary:
	var result := state.duplicate(true)
	var objective_id := str(result.get("objective_id", "clear_all"))
	var advances := false
	match objective_id:
		"defeat_elite":
			advances = bool(enemy_data.get("is_elite", false)) or bool(enemy_data.get("is_boss", false))
		"defeat_boss":
			advances = bool(enemy_data.get("is_boss", false))
		_:
			advances = true
	if advances:
		result["current_count"] = mini(int(result.get("target_count", 1)), int(result.get("current_count", 0)) + 1)
	result["completed"] = int(result.get("current_count", 0)) >= int(result.get("target_count", 1))
	result["hud_text"] = build_hud_text(result)
	return result

static func build_hud_text(state: Dictionary) -> String:
	var objective_id := str(state.get("objective_id", "clear_all"))
	var current := int(state.get("current_count", 0))
	var target := maxi(1, int(state.get("target_count", 1)))
	match objective_id:
		"defeat_elite":
			return "Objective: Defeat elite %d/%d" % [current, target]
		"defeat_boss":
			return "Objective: Break the gatekeeper %d/%d" % [current, target]
		_:
			return "Objective: Clear enemies %d/%d" % [current, target]

static func _count_targets(objective_id: String, enemies: Array) -> int:
	if objective_id == "defeat_elite":
		var elite_count := 0
		for entry in enemies:
			var spawn := Dictionary(entry)
			var modifiers := Dictionary(spawn.get("modifiers", {}))
			if bool(modifiers.get("boss", false)) or bool(modifiers.get("elite", false)):
				elite_count += 1
			elif Array(modifiers.get("elite_affixes", [])).size() > 0:
				elite_count += 1
		return elite_count
	if objective_id == "defeat_boss":
		var boss_count := 0
		for entry in enemies:
			var spawn := Dictionary(entry)
			var modifiers := Dictionary(spawn.get("modifiers", {}))
			if bool(modifiers.get("boss", false)):
				boss_count += 1
		return boss_count
	return enemies.size()
