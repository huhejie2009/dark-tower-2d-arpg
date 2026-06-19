extends RefCounted
class_name P2LootLoopAcceptanceService

const TARGET_MINUTES := 10

static func build_acceptance() -> Dictionary:
	return {
		"phase_id": "P2",
		"phase_name": "Combat Feel And Loot Motivation",
		"target_minutes": TARGET_MINUTES,
		"pass_rule": "10 minute loot loop passes when floor progress, loot volume, upgrade visibility, equipment change, skill growth, and stability gates are met.",
		"items": [
			_make_item("P2-LOOP-FLOOR", "floors_cleared", 3, "Clear at least 3 floors in 10 minutes so the climb does not stall on one room.", "Floor pacing is too slow. Check enemy count, movement distance, exits, and objective clarity."),
			_make_item("P2-LOOP-LOOT", "items_picked", 8, "Pick up at least 8 items so the player receives steady loot feedback.", "Loot density is too low. Check LootRules, pickup distance, and HUD notifications."),
			_make_item("P2-LOOP-EQUIPMENT", "equipment_picked", 1, "Pick up at least 1 equipment item so inventory comparison has a target.", "Equipment drops are too rare. Check equipment probability, elite drops, and boss rewards."),
			_make_item("P2-LOOP-UPGRADE", "upgrade_candidates_seen", 1, "See at least 1 upgrade candidate or explicit recommendation.", "Upgrade motivation is unclear. Check recommendation thresholds, gear score, and readable loot prompts."),
			_make_item("P2-LOOP-EQUIP", "equipment_changes", 1, "Change equipment at least once so loot connects to character growth.", "Equipment-change motivation or operation path is weak. Check item comparison and inventory actions."),
			_make_item("P2-LOOP-SKILL", "skill_upgrades", 1, "Gain or spend at least 1 skill-growth opportunity.", "Growth feedback is weak. Check XP, level-up, skill points, and upgrade preview."),
			_make_item("P2-LOOP-STABILITY", "p0_defects", 0, "P0 blocking defects must stay at 0.", "Fix blocking defects before adding more content.", "max"),
		],
		"gates": [
			{"id": "P2-GATE-REGRESSION", "metric_key": "regression_passed", "acceptance": "Full regression must pass."},
			{"id": "P2-GATE-HEADLESS", "metric_key": "headless_exit_zero", "acceptance": "Main project headless boot must exit with code 0."},
		],
	}

static func evaluate_metrics(metrics: Dictionary) -> Dictionary:
	var checklist := build_acceptance()
	var failed_items: Array = []
	var passed_count := 0
	var items: Array = Array(checklist.get("items", []))
	for item in items:
		var entry: Dictionary = Dictionary(item)
		var ok := _item_passed(entry, metrics)
		if ok:
			passed_count += 1
		else:
			failed_items.append({
				"id": str(entry.get("id", "")),
				"metric_key": str(entry.get("metric_key", "")),
				"required": int(entry.get("target", 0)),
				"actual": _metric_value(metrics, str(entry.get("metric_key", ""))),
				"failure_hint": str(entry.get("failure_hint", "")),
			})
	var gates_passed := bool(metrics.get("regression_passed", false)) and bool(metrics.get("headless_exit_zero", false))
	var no_blockers := int(metrics.get("p0_defects", 0)) <= 0
	var enough_minutes := int(metrics.get("minutes_played", 0)) >= TARGET_MINUTES
	var passed := failed_items.is_empty() and gates_passed and no_blockers and enough_minutes
	var ratio := float(passed_count) / float(maxi(1, items.size()))
	return {
		"phase_id": "P2",
		"target_minutes": TARGET_MINUTES,
		"minutes_played": int(metrics.get("minutes_played", 0)),
		"passed": passed,
		"completion_ratio": ratio,
		"failed_items": failed_items,
		"gates_passed": gates_passed,
		"summary_text": _build_summary_text(passed, failed_items, gates_passed, enough_minutes),
		"next_focus": _build_next_focus(failed_items),
		"next_actions": _build_next_actions(failed_items, gates_passed, enough_minutes),
	}

static func _make_item(id: String, metric_key: String, target: int, acceptance: String, failure_hint: String, compare_mode: String = "min") -> Dictionary:
	return {
		"id": id,
		"metric_key": metric_key,
		"target": target,
		"compare_mode": compare_mode,
		"acceptance": acceptance,
		"failure_hint": failure_hint,
	}

static func _item_passed(item: Dictionary, metrics: Dictionary) -> bool:
	var key := str(item.get("metric_key", ""))
	var target := int(item.get("target", 0))
	var actual := _metric_value(metrics, key)
	if str(item.get("compare_mode", "min")) == "max":
		return actual <= target
	return actual >= target

static func _metric_value(metrics: Dictionary, key: String) -> int:
	return maxi(0, int(metrics.get(key, 0)))

static func _build_summary_text(passed: bool, failed_items: Array, gates_passed: bool, enough_minutes: bool) -> String:
	if passed:
		return "P2 10 minute loot loop ready: loot loop ready for focused manual playtest."
	if not enough_minutes:
		return "P2 loot loop blocked: playtest duration is below 10 minutes."
	if not gates_passed:
		return "P2 loot loop blocked: regression or headless gate failed."
	return "P2 loot loop blocked: %d goals need attention." % failed_items.size()

static func _build_next_focus(failed_items: Array) -> String:
	if failed_items.is_empty():
		return "Tune pacing and prepare 10 minute manual playtest notes."
	return str(Dictionary(failed_items[0]).get("failure_hint", "Review failed loot loop goals."))

static func _build_next_actions(failed_items: Array, gates_passed: bool, enough_minutes: bool) -> Array[String]:
	var actions: Array[String] = []
	if not enough_minutes:
		actions.append("Run or simulate a full 10-minute playtest sample before judging loot pacing.")
	if not gates_passed:
		actions.append("Fix full regression or headless boot gates before accepting P2.")
	for item in failed_items:
		var hint := str(Dictionary(item).get("failure_hint", ""))
		if hint != "" and not actions.has(hint):
			actions.append(hint)
		if actions.size() >= 4:
			break
	if actions.is_empty():
		actions.append("Record manual playtest feedback and continue pacing polish.")
	return actions
