# 2026-06-09 背包容量规则进度

## 对应 ROADMAP

继续推进 P2“战斗手感与刷宝驱动”中的可读性与刷宝循环稳定性。本轮不新增代码生成素材，不清除玩家存档，不改变美术方向。

## 本轮目标

把原本只靠“物品数量较高”的软提示，升级为明确的背包容量规则，为后续满包提示、清包、出售、分解、仓库、红点 UI 留出统一接口。

## 已完成

新增 `InventoryDataService` 容量接口：

- `get_default_capacity()`
- `get_used_slots(inventory)`
- `build_capacity_summary(inventory, capacity = 40)`

当前规则：

- 默认容量：40 格。
- 装备：每个装备实例占 1 格。
- 货币/材料等可堆叠物：按物品 ID 堆叠后占 1 格。
- 背包压力线：80%，即 32/40。
- 当前阶段只提示压力，不阻止拾取，避免突然破坏刷宝节奏。

已接入：

- 主城准备摘要显示 `Bag used/capacity`。
- 主城准备建议中的 `Bag pressure` 改为读取容量摘要。
- 战斗 HUD 的背包提示显示容量摘要。
- 背包装备窗口标题显示容量摘要，并在压力状态下用主题强调色提示。

## 新增验证

- `tests/regression/regression_inventory_capacity_rules.gd`

聚焦验证标记：

- `NEW_PROJECT_INVENTORY_CAPACITY_RULES_OK`

相关回归已验证：

- `NEW_PROJECT_TOWN_PREP_RECOMMENDATION_SERVICE_OK`
- `NEW_PROJECT_TOWN_PREP_SUMMARY_SERVICE_OK`
- `NEW_PROJECT_HUD_VITALS_CONTRACT_OK`
- `NEW_PROJECT_INVENTORY_TOOLS_CONTRACT_OK`

## 后续接口

后续可以在不改 UI 调用方的前提下继续扩展：

- 满包状态：`full == true` 时阻止拾取或自动转入临时掉落队列。
- 背包容量升级：把默认 40 改为玩家数据字段。
- 分解/出售：清理装备格后刷新同一份容量摘要。
- UI 红点/容量条：直接读取 `pressure_ratio`、`free_slots`、`summary_text`。
- QA 面板：记录每轮爬塔时的容量压力峰值，判断玩家是否被迫频繁清包。
