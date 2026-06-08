extends RefCounted
class_name P2LootLoopMetricsRecorder

const P2LootLoopAcceptanceServiceScript := preload("res://scripts/data/P2LootLoopAcceptanceService.gd")

const METRIC_KEYS: Array[String] = [
	"minutes_played",
	"floors_cleared",
	"items_picked",
	"equipment_picked",
	"upgrade_candidates_seen",
	"equipment_changes",
	"skill_upgrades",
	"deaths",
	"p0_defects",
	"p1_defects",
]

static func create_metrics() -> Dictionary:
	var metrics := {
		"elapsed_seconds": 0.0,
		"regression_passed": false,
		"headless_exit_zero": false,
	}
	for key in METRIC_KEYS:
		metrics[key] = 0
	return metrics

static func normalize_metrics(metrics: Dictionary) -> Dictionary:
	var result := metrics.duplicate(true)
	for key in METRIC_KEYS:
		result[key] = maxi(0, int(result.get(key, 0)))
	result["elapsed_seconds"] = maxf(0.0, float(result.get("elapsed_seconds", float(result.get("minutes_played", 0)) * 60.0)))
	result["minutes_played"] = int(floor(float(result.get("elapsed_seconds", 0.0)) / 60.0))
	result["regression_passed"] = bool(result.get("regression_passed", false))
	result["headless_exit_zero"] = bool(result.get("headless_exit_zero", false))
	return result

static func record_elapsed_seconds(metrics: Dictionary, elapsed_seconds: float) -> Dictionary:
	var result := normalize_metrics(metrics)
	result["elapsed_seconds"] = maxf(float(result.get("elapsed_seconds", 0.0)), elapsed_seconds)
	result["minutes_played"] = int(floor(float(result.get("elapsed_seconds", 0.0)) / 60.0))
	return result

static func add_elapsed_seconds(metrics: Dictionary, delta_seconds: float) -> Dictionary:
	var result := normalize_metrics(metrics)
	result["elapsed_seconds"] = maxf(0.0, float(result.get("elapsed_seconds", 0.0)) + delta_seconds)
	result["minutes_played"] = int(floor(float(result.get("elapsed_seconds", 0.0)) / 60.0))
	return result

static func record_floor_cleared(metrics: Dictionary) -> Dictionary:
	return _increment_metric(metrics, "floors_cleared")

static func record_pickup(metrics: Dictionary, payload: Dictionary, notification: Dictionary = {}) -> Dictionary:
	var result := _increment_metric(metrics, "items_picked")
	if str(payload.get("type", "")) == "equipment":
		result = _increment_metric(result, "equipment_picked")
	if _is_upgrade_candidate(notification):
		result = _increment_metric(result, "upgrade_candidates_seen")
	return result

static func record_equipment_change(metrics: Dictionary) -> Dictionary:
	return _increment_metric(metrics, "equipment_changes")

static func record_skill_upgrade(metrics: Dictionary) -> Dictionary:
	return _increment_metric(metrics, "skill_upgrades")

static func record_death(metrics: Dictionary) -> Dictionary:
	return _increment_metric(metrics, "deaths")

static func record_defect(metrics: Dictionary, severity: String) -> Dictionary:
	var key := "p0_defects" if severity.to_upper() == "P0" else "p1_defects"
	return _increment_metric(metrics, key)

static func set_verification_gates(metrics: Dictionary, regression_passed: bool, headless_exit_zero: bool) -> Dictionary:
	var result := normalize_metrics(metrics)
	result["regression_passed"] = regression_passed
	result["headless_exit_zero"] = headless_exit_zero
	return result

static func build_acceptance_report(metrics: Dictionary) -> Dictionary:
	return P2LootLoopAcceptanceServiceScript.evaluate_metrics(normalize_metrics(metrics))

static func _increment_metric(metrics: Dictionary, key: String, amount: int = 1) -> Dictionary:
	var result := normalize_metrics(metrics)
	result[key] = maxi(0, int(result.get(key, 0)) + amount)
	return result

static func _is_upgrade_candidate(notification: Dictionary) -> bool:
	if bool(notification.get("upgrade", false)):
		return true
	var rank := str(notification.get("recommendation_rank", ""))
	return rank == "upgrade" or rank == "strong_upgrade"
