extends RefCounted
class_name DivinePressureService

const MIN_WARNING_SECONDS := 0.6

static func build_event_config(trigger: String, floor: int) -> Dictionary:
	var safe_floor := maxi(1, floor)
	return {
		"trigger": trigger,
		"warning_seconds": MIN_WARNING_SECONDS + minf(0.35, float(safe_floor) * 0.02),
		"radius": 92.0 + minf(36.0, float(safe_floor) * 3.0),
		"damage": 10 + int(float(safe_floor) * 1.5),
		"color_role": "enemy_pressure_warning",
		"blocks_portal": false,
	}

static func should_trigger_after_enemy(enemy_data: Dictionary, event_active: bool) -> bool:
	if event_active:
		return false
	return bool(enemy_data.get("is_elite", false)) or bool(enemy_data.get("is_boss", false))
