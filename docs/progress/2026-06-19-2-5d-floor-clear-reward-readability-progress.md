# 2026-06-19 2.5D 清层奖励可读性进度

## 目标

让玩家清完一层后能直接从 HUD 日志读懂：

- 刚刚清的是第几层。
- 获得了多少金币。
- 是否获得水晶。
- Boss 层是否有保底装备。
- 下一步应该进入蓝色出口继续爬塔。

## 已完成

- `Prototype2_5DCombatRoom` 新增 `last_floor_clear_summary_text`。
- 清层后会构建一条紧凑摘要，例如：
  - `Floor 5 clear. Gold 98. Crystal 1. Boss reward x1. Next: enter the blue exit marker.`
- HUD 日志现在显示清层奖励摘要，而不是只显示“Floor clear”。
- `build_loot_xp_reward_snapshot_for_test()` 暴露：
  - `floor_clear_summary_text`
  - `hud_log_text`
- 回归测试要求 Boss 清层摘要包含金币、水晶、Boss 奖励和下一步动作。

## 验证

- 红测先失败，失败点为缺少清层摘要字段和 HUD 日志摘要。
- 实现后通过：`NEW_PROJECT_PROTOTYPE_2_5D_LOOT_XP_REWARD_BRIDGE_OK`。

## 后续建议

- 下一轮可以把这条摘要升级为更正式的清层小面板，但当前阶段先保留 HUD 日志，避免继续扩大 UI 重构范围。
