# 2026-06-07 掉落质量曲线第一轮进度

## 本轮目标

继续推进 ROADMAP P2 / T-008「掉落质量曲线」。目标是让掉落不再只是固定节奏，而是带有可统计、可调参、可被 UI/VFX/音效复用的质量 payload。

本轮不生成素材，不改玩家存档。

## 已完成

- 新增 `LootQualityService`。
- 质量 profile 由以下输入生成：
  - 楼层 `floor`
  - 来源 `source`：normal / elite / boss
  - 击杀序号 `kill_index`
- 质量 profile 输出：
  - `item_level`
  - `equipment_chance`
  - `magic_chance`
  - `rare_chance`
  - `legendary_chance`
  - `guaranteed_equipment`
  - `quality_tag`
- `LootRules.generate_enemy_drop` 保持旧签名兼容，同时现在会给 payload 增加：
  - `source`
  - `loot_quality`
- 新增 `LootRules.generate_enemy_drop_with_source`，为精英、Boss、事件房等后续来源留接口。
- 新增 `LootRules.sample_floor_loot_quality_for_test`，用于统计某楼层掉落质量。
- Boss 奖励升级为 rare+。
- 精英装备至少 magic，并稳定出现 rare+。
- 旧 Boss 奖励入包测试升级为 magic-or-better 语义。

## 新增/更新验证

- `regression_loot_quality_service.gd`
- `regression_loot_quality_rules.gd`
- `regression_boss_reward_inventory_bridge.gd`
- 聚焦验证：`FOCUSED_P2_LOOT_QUALITY_REGRESSION_OK`

## ROADMAP 更新

- 新增版本：`docs/planning/2026-06-07-dark-tower-2d-arpg-production-roadmap-updated-p2-loot-quality.xlsx`
- T-008 状态更新为「第一轮完成」。
- P2 完成率更新到 45%。

## 后续衔接

推荐下一步进入 P2 的装备推荐和刷宝目标强化：

1. 让装备推荐从 `loot_quality`、装备评分和当前穿戴差距共同判断。
2. 掉落通知可以显示“稀有来源”“Boss 奖励”“升级候选”等更明确的短标签。
3. 后续稀有光柱、掉落音效、飘字颜色都读取同一份 payload，不写进掉落生成逻辑。
