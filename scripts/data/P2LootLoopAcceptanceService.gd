extends RefCounted
class_name P2LootLoopAcceptanceService

const TARGET_MINUTES := 10

static func build_acceptance() -> Dictionary:
	return {
		"phase_id": "P2",
		"phase_name": "战斗手感与刷宝驱动",
		"target_minutes": TARGET_MINUTES,
		"pass_rule": "10 minute loot loop passes when floor progress, loot volume, upgrade visibility, equipment change, skill growth and stability gates are met.",
		"items": [
			_make_item("P2-LOOP-FLOOR", "floors_cleared", 3, "10 分钟内至少清 3 层，节奏不能卡在单层。", "楼层节奏过慢，优先检查敌人数量、移动距离、传送门流程。"),
			_make_item("P2-LOOP-LOOT", "items_picked", 8, "10 分钟内至少拾取 8 个物品，形成持续掉落反馈。", "掉落密度不足，优先检查 LootRules、拾取距离、HUD 提示。"),
			_make_item("P2-LOOP-EQUIPMENT", "equipment_picked", 1, "至少拾取 1 件装备，让背包比较有对象。", "装备掉落不足，优先检查装备掉落概率和 Boss/精英来源。"),
			_make_item("P2-LOOP-UPGRADE", "upgrade_candidates_seen", 1, "至少看到 1 次升级候选或明确推荐。", "刷宝目标不清，优先检查推荐阈值、装备评分和提示可读性。"),
			_make_item("P2-LOOP-EQUIP", "equipment_changes", 1, "至少实际换装 1 次，形成掉落到成长的闭环。", "换装动机不足，优先检查装备差异、背包详情和操作路径。"),
			_make_item("P2-LOOP-SKILL", "skill_upgrades", 1, "至少完成 1 次技能升级或获得可升级目标。", "成长反馈不足，优先检查经验、技能点、升级预览。"),
			_make_item("P2-LOOP-STABILITY", "p0_defects", 0, "P0 阻塞缺陷必须为 0。", "先修阻塞缺陷，再继续扩内容。", "max"),
		],
		"gates": [
			{"id": "P2-GATE-REGRESSION", "metric_key": "regression_passed", "acceptance": "完整回归通过。"},
			{"id": "P2-GATE-HEADLESS", "metric_key": "headless_exit_zero", "acceptance": "主项目 headless 启动退出码为 0。"},
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
		actions.append("补足 10 分钟试玩样本，再判断刷宝节奏。")
	if not gates_passed:
		actions.append("先修完整回归或 headless 启动门禁。")
	for item in failed_items:
		var hint := str(Dictionary(item).get("failure_hint", ""))
		if hint != "" and not actions.has(hint):
			actions.append(hint)
		if actions.size() >= 4:
			break
	if actions.is_empty():
		actions.append("记录人工试玩反馈，继续微调刷宝节奏。")
	return actions
