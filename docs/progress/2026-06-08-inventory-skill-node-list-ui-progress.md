# 2026-06-08 背包技能节点列表 UI 进度

## 本轮目标

继续推进 ROADMAP P2「战斗手感与刷宝驱动」。本轮把上一轮的三节点技能成长服务接入背包右侧 Skills 区，让玩家不再只能看到基础攻击训练，而是能在背包内看到并选择多个成长节点。

本轮不生成代码素材，不清除玩家存档。

## 已完成

- `InventoryEquipmentWindow` 新增紧凑技能节点列表：
  - `SkillNodeList`
  - `SkillNodeBasicAttackTraining`
  - `SkillNodeVitalityTraining`
  - `SkillNodePrecisionTraining`
- 新增通用升级按钮：
  - `UpgradeSelectedSkillButton`
- 新增/保留测试和后续 UI 接口：
  - `select_skill_node(node_id)`
  - `upgrade_selected_skill_node()`
  - `get_selected_skill_node_id()`
  - `get_skill_node_previews_for_test()`
  - `get_basic_attack_upgrade_preview_for_test()`
- 旧的 `UpgradeBasicAttackButton` 保持兼容。
- 技能区现在会根据选中节点显示对应的等级、收益、消耗和阻塞原因。

## 新增验证

- `tests/regression/regression_inventory_skill_node_list_ui.gd`
- 聚焦回归：
  - `FOCUSED_P2_SKILL_NODE_UI_REGRESSION_OK`

## ROADMAP 更新

- 新增版本：
  - `docs/planning/2026-06-08-dark-tower-2d-arpg-production-roadmap-updated-p2-skill-node-ui.xlsx`
- P2 完成率更新到 83%。
- T-009 更新为「刷宝目标、装备推荐、对比摘要与技能成长 UI 可读性」。

## 为后续保留的接口

- 未来正式技能树窗口可以复用 `select_skill_node` 和 `upgrade_selected_skill_node`。
- 未来正式图标只需要映射 `node_id`，不需要改升级逻辑。
- 未来升级音效、按钮闪光、教学提示可以读取当前选中节点 preview payload。

## 后续推荐

1. 进行一次 P2 10 分钟人工试玩，把 `P2LootLoopAcceptanceService` 的指标填实。
2. 准备 P3 的 3-5 个楼层模板节奏变化。
3. 后续再做正式技能树视觉，不要在当前阶段扩大成复杂天赋盘。
