extends RefCounted
class_name PlaytestAcceptanceService

static func build_phase_acceptance(phase_id: String) -> Dictionary:
	if phase_id != "P1":
		return {
			"phase_id": phase_id,
			"phase_name": "Unknown phase",
			"target_minutes": 0,
			"items": [],
			"gates": [],
			"pass_rule": "No acceptance checklist is defined for this phase yet.",
			"next_phase": "",
		}
	return {
		"phase_id": "P1",
		"phase_name": "可试玩 UI 与装备闭环",
		"target_minutes": 30,
		"pass_rule": "P0 阻塞缺陷必须为 0；P1 严重缺陷不超过 2；完整回归通过；主项目 headless 启动退出码为 0。",
		"next_phase": "P2",
		"items": _build_p1_items(),
		"gates": _build_p1_gates(),
	}

static func evaluate_phase_report(phase_id: String, report: Dictionary) -> Dictionary:
	var checklist := build_phase_acceptance(phase_id)
	var p0 := int(report.get("P0", 0))
	var p1 := int(report.get("P1", 0))
	var minutes_played := int(report.get("minutes_played", 0))
	var regression_passed := bool(report.get("regression_passed", false))
	var headless_exit_zero := bool(report.get("headless_exit_zero", false))
	var passed := p0 == 0 and p1 <= 2 and minutes_played >= int(checklist.get("target_minutes", 0)) and regression_passed and headless_exit_zero
	var blockers: Array[String] = []
	if p0 > 0:
		blockers.append("P0 blockers must be zero.")
	if p1 > 2:
		blockers.append("P1 severe defects must be 2 or fewer.")
	if minutes_played < int(checklist.get("target_minutes", 0)):
		blockers.append("Playtest duration is below target.")
	if not regression_passed:
		blockers.append("Full regression must pass.")
	if not headless_exit_zero:
		blockers.append("Main headless startup must exit 0.")
	return {
		"phase_id": phase_id,
		"passed": passed,
		"blockers": blockers,
		"next_phase": str(checklist.get("next_phase", "")) if passed else phase_id,
		"summary": "Phase %s accepted." % phase_id if passed else "Phase %s is blocked." % phase_id,
	}

static func _build_p1_items() -> Array[Dictionary]:
	return [
		{
			"id": "P1-SAVE-001",
			"area": "存档/角色",
			"owner": "系统策划 + 程序",
			"acceptance": "玩家能进入存档槽/角色流程，旧存档不会被清除，角色数据可正常读取。",
			"verification": "建号、回主城、进入战斗、退出重进；检查 SaveManager/SaveSchema 回归。",
			"severity_if_failed": "P0",
		},
		{
			"id": "P1-INV-001",
			"area": "背包",
			"owner": "UI/系统",
			"acceptance": "背包物品点击只选中不误装备；可筛选、排序、锁定；格子能显示稀有度和更强提示。",
			"verification": "打开背包，选中装备/材料/货币，切换筛选与排序，检查 E/+ 标识。",
			"severity_if_failed": "P1",
		},
		{
			"id": "P1-EQP-001",
			"area": "装备",
			"owner": "UI/系统",
			"acceptance": "装备窗口有纸娃娃面板、职业、总评分、槽位摘要；穿脱装备后属性和背包状态同步。",
			"verification": "装备/卸下武器和护甲，确认 Gear Score、Stats、槽位文本更新。",
			"severity_if_failed": "P1",
		},
		{
			"id": "P1-LOOT-001",
			"area": "掉落提示",
			"owner": "战斗/UI",
			"acceptance": "拾取材料、货币、装备时有独立提示；更强装备和 Boss 奖励能被区分。",
			"verification": "击杀敌人拾取掉落；清 Boss 楼层；查看 HUD 掉落提示和背包新增物。",
			"severity_if_failed": "P2",
		},
		{
			"id": "P1-DEATH-001",
			"area": "死亡结算",
			"owner": "系统/UI",
			"acceptance": "死亡后结算展示楼层、击杀、拾取、Boss 奖励、回城半血；背包和装备保留。",
			"verification": "主动死亡，检查结算页与返回主城后的角色状态。",
			"severity_if_failed": "P0",
		},
		{
			"id": "P1-PAUSE-001",
			"area": "暂停/回城",
			"owner": "UI/流程",
			"acceptance": "Esc 暂停、继续、打开背包、回城流程清晰，不与死亡结算冲突。",
			"verification": "战斗内多次 Esc、I/C、回城；死亡结算出现后检查焦点。",
			"severity_if_failed": "P1",
		},
		{
			"id": "P1-FLOOR-001",
			"area": "楼层稳定",
			"owner": "关卡/程序",
			"acceptance": "清怪开门/传送门稳定；进入下一层不死锁；连续 10 层稳定测试通过。",
			"verification": "清层、按 E、进传送门；运行 regression_ten_floor_stability.gd。",
			"severity_if_failed": "P0",
		},
		{
			"id": "P1-REG-001",
			"area": "回归门禁",
			"owner": "QA/程序",
			"acceptance": "完整回归通过，场景烟测通过，主项目 headless 启动退出码为 0。",
			"verification": "运行完整 regression、regression_scene_boot.gd、--quit-after 1。",
			"severity_if_failed": "P0",
		},
	]

static func _build_p1_gates() -> Array[Dictionary]:
	return [
		{"id": "G0", "name": "启动门禁", "required": "主项目 headless 启动退出码 0。"},
		{"id": "G1", "name": "完整回归", "required": "输出 ALL_NEW_PROJECT_REGRESSION_OK。"},
		{"id": "G2", "name": "场景烟测", "required": "MainMenu/CharacterSelect/Town/Game2D 全部启动。"},
		{"id": "G3", "name": "试玩门禁", "required": "30 分钟内部试玩无 P0，P1 不超过 2 个。"},
		{"id": "G4", "name": "存档门禁", "required": "不清存档；旧数据可 normalize；死亡/回城不丢背包装备。"},
	]
