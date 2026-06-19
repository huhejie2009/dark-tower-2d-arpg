extends RefCounted
class_name TowerRunStartService

static var pending_start_floor: int = -1

static func build_start_options(player_data: Dictionary) -> Dictionary:
	var best_floor := _get_best_floor(player_data)
	return {
		"fresh_floor": 1,
		"best_floor": best_floor,
		"fresh_label": "Enter Tower: Floor 1",
		"best_label": "Challenge Best Floor %d" % best_floor,
		"fresh_description": "Start a new climb from Floor 1. This does not erase saved progress.",
		"best_description": "Challenge Floor %d from saved progress." % best_floor,
		"highest_floor_explanation": "highest_floor is saved progression. current_floor is the active run floor.",
		"explanation_text": "Floor 1 starts a fresh climb; Best Floor uses saved progress from highest_floor.",
	}

static func request_start_floor(floor: int) -> void:
	pending_start_floor = floor

static func request_fresh_run() -> void:
	request_start_floor(1)

static func request_best_floor(player_data: Dictionary) -> void:
	request_start_floor(_get_best_floor(player_data))

static func consume_start_floor(player_data: Dictionary) -> int:
	var requested := pending_start_floor
	pending_start_floor = -1
	if requested < 0:
		return 1
	return clampi(requested, 1, _get_best_floor(player_data))

static func _get_best_floor(player_data: Dictionary) -> int:
	return maxi(1, int(player_data.get("highest_floor", 1)))
