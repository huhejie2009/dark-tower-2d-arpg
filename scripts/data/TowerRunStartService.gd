extends RefCounted
class_name TowerRunStartService

static var pending_start_floor: int = -1

static func build_start_options(player_data: Dictionary) -> Dictionary:
	var best_floor := _get_best_floor(player_data)
	return {
		"fresh_floor": 1,
		"best_floor": best_floor,
		"fresh_label": "进入通天塔：第 1 层",
		"best_label": "挑战最高层：第 %d 层" % best_floor,
		"fresh_description": "从第 1 层开始新的爬塔，不会清除已保存进度。",
		"best_description": "从已保存进度挑战第 %d 层。" % best_floor,
		"highest_floor_explanation": "最高层是已保存的爬塔进度；当前层只代表本次挑战。",
		"explanation_text": "第 1 层用于重新开爬；最高层会读取已保存进度。",
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
