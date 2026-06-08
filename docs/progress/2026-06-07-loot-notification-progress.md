# 2026-06-07 战斗内掉落提示进度

## 对应 ROADMAP

- 阶段：P1 可试玩 UI 与装备闭环
- 任务：T-003 战斗内掉落提示

## 本轮目标

拾取掉落时，不再只在普通日志里显示物品名，而是生成结构化掉落提示。该接口后续可继续用于稀有光柱、音效、Boss 奖励弹窗、装备推荐和掉落统计。

## 已完成

- 新增 `scripts/data/LootNotificationService.gd`
  - `build_pickup_notification(player_data, payload, source = "drop")`
  - 返回物品名、类型、数量、稀有度、装备分数、是否更强、是否 Boss 奖励、提示标题、日志文本、强调色。
- `HudController` 新增独立掉落提示层：
  - `LootNotificationLabel`
  - `show_loot_notification(notification)`
  - `get_last_loot_notification_for_test()`
- `Game2D` 接入掉落提示：
  - 敌人掉落拾取前先生成通知，再进入背包。
  - Boss 奖励使用 `source = "boss_reward"` 生成可区分通知。
  - 保留 `last_loot_notification`，供后续弹窗、音效、测试复用。

## 回归覆盖

新增：

- `tests/regression/regression_loot_notification_service.gd`
- `tests/regression/regression_hud_loot_notification_contract.gd`
- `tests/regression/regression_game2d_loot_notification_bridge.gd`

已验证：

- `NEW_PROJECT_LOOT_NOTIFICATION_SERVICE_OK`
- `NEW_PROJECT_HUD_LOOT_NOTIFICATION_CONTRACT_OK`
- `NEW_PROJECT_GAME2D_LOOT_NOTIFICATION_BRIDGE_OK`
- `FOCUSED_LOOT_NOTIFICATION_REGRESSION_OK`

## ROADMAP 更新

已另存更新版：

- `docs/planning/2026-06-07-dark-tower-2d-arpg-production-roadmap-updated-p1-loot-notification.xlsx`

更新内容：

- T-003 状态改为 `已完成`。
- P1 完成率更新为 `55%`。

## 下一步建议

继续执行 P1：

- T-004 装备窗口纸娃娃布局。
- 或先补一轮战斗拾取视觉动画，让 `LootNotificationLabel` 变成更正式的提示条。
