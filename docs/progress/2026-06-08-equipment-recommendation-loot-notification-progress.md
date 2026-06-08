# 2026-06-08 装备推荐与掉落提示强化进度

## 本轮目标

继续推进 ROADMAP P2。目标是让掉落通知从“显示物品”升级为“告诉玩家这件东西为什么值得看”，并把推荐逻辑服务化，供背包、掉落通知、未来光柱/音效/UI 标签复用。

本轮不生成素材，不改玩家存档。

## 已完成

- 新增 `EquipmentRecommendationService`。
- 推荐 payload 包含：
  - `score`
  - `equipped_score`
  - `score_delta`
  - `upgrade`
  - `recommendation_rank`
  - `recommendation_text`
  - `source_label`
  - `quality_tag`
  - `equip_reason`
- `LootNotificationService` 接入推荐服务。
- 掉落通知现在能携带：
  - Boss / 精英 / 普通来源标签
  - `loot_quality.quality_tag`
  - 装备评分差距
  - 推荐强度
  - 短标签 `short_tag`
- `HudController` 只负责展示通知字段，不承载推荐判断逻辑。

## 新增/更新验证

- `regression_equipment_recommendation_service.gd`
- `regression_loot_notification_recommendation_tags.gd`
- 聚焦验证：`FOCUSED_P2_RECOMMENDATION_REGRESSION_OK`

## ROADMAP 更新

- 新增版本：`docs/planning/2026-06-08-dark-tower-2d-arpg-production-roadmap-updated-p2-recommendation.xlsx`
- P2 完成率更新到 55%。
- T-009 状态更新为「第一轮完成」。

## 注意

当前 Codex 沙箱会拦截 Godot 写入 `user://logs`，导致普通沙箱运行 Godot 时可能触发引擎崩溃。测试已在提升权限下完成，项目回归本身通过。

## 后续衔接

推荐下一步继续 P2 的刷宝目标可读性：

1. 背包物品格显示推荐标签或小标记。
2. 掉落通知把 `recommendation_rank` 映射成更明确的短文案。
3. 后续稀有光柱、音效和拾取反馈读取同一份推荐 payload。
