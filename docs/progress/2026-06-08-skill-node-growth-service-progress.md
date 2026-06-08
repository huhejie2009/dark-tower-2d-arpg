# 2026-06-08 三节点技能成长服务进度

## 本轮目标

继续推进 ROADMAP P2「战斗手感与刷宝驱动」。本轮把技能成长从单一“基础攻击训练”扩展为最小三节点成长接口，为后续技能树 UI、正式图标、升级音效、教学提示和可视化面板预留统一数据源。

本轮不生成代码素材，不清除玩家存档。

## 已完成

- 新增 `SkillNodeGrowthService`。
- 第一版节点：
  - `basic_attack_training`：攻击伤害 +3
  - `vitality_training`：最大生命 +12，并同步补当前生命
  - `precision_training`：暴击 +2
- 服务提供：
  - `list_nodes()`
  - `get_node(node_id)`
  - `build_preview(player_data, node_id)`
  - `build_all_previews(player_data)`
  - `upgrade_node(player_data, node_id)`
- `SkillUpgradePreviewService` 改为复用 `SkillNodeGrowthService`。
- `PlayerDataService.upgrade_basic_attack()` 保持旧接口兼容，内部转到统一节点升级。

## 新增验证

- `tests/regression/regression_skill_node_growth_service.gd`
- 聚焦回归：
  - `FOCUSED_P2_SKILL_NODE_GROWTH_REGRESSION_OK`

## ROADMAP 更新

- 新增版本：
  - `docs/planning/2026-06-08-dark-tower-2d-arpg-production-roadmap-updated-p2-skill-node-growth.xlsx`
- P2 完成率更新到 80%。
- T-009 更新为「刷宝目标、装备推荐、对比摘要与技能成长可读性」。

## 为后续保留的接口

- 未来技能树窗口可以直接读取 `SkillNodeGrowthService.list_nodes()` 和 `build_all_previews()`。
- 未来正式图标和素材只需要映射 `node_id`，不用改升级逻辑。
- 未来升级成功弹窗、音效、按钮闪光、教学提示可以复用 preview payload。
- 旧的 `upgrade_basic_attack()` API 继续可用，避免现有 UI 和测试被迫一起改。

## 后续推荐

1. 给背包右侧技能区增加一个紧凑节点列表，而不是只显示基础攻击训练。
2. 进行 P2 10 分钟人工试玩，把 `P2LootLoopAcceptanceService` 的 metrics 填实。
3. 进入 P3 前准备 3-5 个楼层模板节奏变化，让刷宝循环不只靠数值推进。
