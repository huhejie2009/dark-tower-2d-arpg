# 2026-06-08 背包装备推荐可读性进度

## 本轮目标

继续推进 ROADMAP P2「战斗手感与刷宝驱动」。本轮重点不是继续扩功能面，而是把上一轮已经服务化的装备推荐信息接入背包窗口，让玩家在背包格子和装备详情里也能看懂「这件装备为什么值得看」。

本轮不生成代码素材，不清除玩家存档。

## 已完成

- `InventoryDataService` 开始保留物品来源元数据：
  - `source`
  - `loot_quality`
- `InventoryEquipmentWindow` 接入 `EquipmentRecommendationService`。
- 背包物品视觉元数据新增：
  - `score`
  - `equipped_score`
  - `score_delta`
  - `recommendation_rank`
  - `recommendation_text`
  - `source_label`
  - `quality_tag`
- 装备详情文本新增：
  - 来源，例如 `Source: Boss reward`
  - 质量标签，例如 `Quality: boss_floor_10`
  - 推荐文本，例如 `Recommendation: +34 upgrade`
  - 分数差，例如 `Score Delta: +34`
- 新增测试接口：
  - `get_item_recommendation_for_test(item_id)`

## 新增验证

- `tests/regression/regression_inventory_recommendation_tags.gd`
- 聚焦回归：
  - `FOCUSED_P2_INVENTORY_RECOMMENDATION_REGRESSION_OK`

## ROADMAP 更新

- 新增版本：
  - `docs/planning/2026-06-08-dark-tower-2d-arpg-production-roadmap-updated-p2-inventory-recommendation.xlsx`
- P2 完成率更新到 62%。
- T-009 更新为「装备推荐与背包可读性」。

## 为后续保留的接口

- 背包格子后续可以直接读取 `recommendation_rank` 映射图标、边框、角标或音效，不需要重新计算推荐逻辑。
- 装备详情、掉落通知、未来商店/铁匠/仓库可以共用 `EquipmentRecommendationService` 输出。
- `InventoryDataService` 保留 `loot_quality` 后，未来 Boss 奖励、精英掉落、任务奖励、商店货源都可以带来源标签进入背包。

## 后续推荐

1. 继续把「装备推荐可读性」扩到装备对比面板，例如把核心属性差异做成更紧凑的正负变化列表。
2. 做背包图标网格的正式 UI 皮肤接口，但仍然不生成代码素材。
3. 推进技能升级可读性，把 P2 中成长目标和刷宝目标串起来。
