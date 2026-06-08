# 2026-06-09 主城准备建议行动入口进度

## 本轮目标

继续按 ROADMAP 推进“第一版稳定可试玩 UI 与稳定性增强”。本轮不新增代码生成素材，不清理玩家存档，重点把主城准备建议从纯文字提示推进为可点击行动入口。

## 已完成

- `TownPrepRecommendationService` 的每条建议补充了结构化行动字段：
  - `action_id`
  - `button_text`
  - 顶层 `primary_action_id`
  - 顶层 `primary_button_text`
  - 顶层 `primary_recommendation_id`
- 主城准备面板新增 `TownPrepActionButton`。
- 当前优先级最高的建议会驱动按钮文案和行为：
  - `open_skills`：打开背包/装备/成长窗口，并聚焦默认技能节点。
  - `open_equipment`：打开背包/装备窗口，并切到装备筛选。
  - `open_inventory`：打开背包/装备窗口，并回到全部物品视图。
- `Town.gd` 暴露了测试/后续系统可用的准备行动接口：
  - `trigger_prep_action_for_test()`
  - `get_prep_primary_action_for_test()`

## 留给后续工作的接口

- 后续如果拆出独立技能树窗口，可以直接让 `open_skills` 路由到新窗口，不需要改推荐服务的数据结构。
- 后续如果装备窗口独立化，可以继续沿用 `open_equipment`。
- 后续如果背包暂停战斗、回城确认、死亡结算统一进入窗口管理器，主城准备按钮可以接入同一套 UI 路由。
- 推荐项仍保持 `id` 和 `priority`，方便以后扩展铁匠、商人、仓库、任务、天赋等入口。

## 验证结果

已通过聚焦回归：

- `NEW_PROJECT_TOWN_PREP_RECOMMENDATION_SERVICE_OK`
- `NEW_PROJECT_TOWN_PREP_ACTION_BUTTON_OK`

已通过相邻回归：

- `NEW_PROJECT_TOWN_PREP_PANEL_CONTRACT_OK`
- `NEW_PROJECT_TOWN_PREP_SUMMARY_SERVICE_OK`
- `NEW_PROJECT_INVENTORY_EQUIPMENT_ACTION_HINTS_OK`
- `NEW_PROJECT_INVENTORY_SKILL_NODE_LIST_UI_OK`
- `NEW_PROJECT_INVENTORY_TOOLS_CONTRACT_OK`
- `NEW_PROJECT_SCENE_BOOT_ALL_OK`

## 下一步建议

优先继续做“背包/装备窗口实战可读性与暂停安全”：

1. 战斗内打开背包时强制暂停并锁定敌人行为。
2. 装备列表加入更明显的“可装备/升级/当前装备/职业不匹配”状态。
3. 背包窗口从固定覆盖式改为更清晰的暂停层布局，避免玩家看不清当前能用什么。
4. 给装备、技能、消耗品建立统一 action router，减少后续窗口互相直连。
