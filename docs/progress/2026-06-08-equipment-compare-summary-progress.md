# 2026-06-08 装备对比摘要服务化进度

## 本轮目标

继续推进 ROADMAP P2「战斗手感与刷宝驱动」。本轮重点是把背包详情里的装备对比从 UI 字符串拼接升级为结构化摘要，让玩家更快看懂换装收益，也让后续正式装备卡、悬浮提示、图标角标、音效提示能复用同一份数据。

本轮不生成代码素材，不清除玩家存档。

## 已完成

- 新增 `EquipmentCompareSummaryService`。
- 装备对比摘要 payload 包含：
  - `slot`
  - `candidate_item_id`
  - `equipped_item_id`
  - `candidate_score`
  - `equipped_score`
  - `score_delta`
  - `headline`
  - `stat_deltas`
  - `compact_text`
  - `empty_slot`
- `InventoryEquipmentWindow` 接入对比摘要服务。
- 装备详情现在增加 `Compare Summary` 段，显示：
  - 升级/降级/横向替换判断
  - 评分差
  - 前几个核心属性变化
- 旧的 `Compare:` 文本继续保留，并改为从同一份结构化摘要生成，兼容已有测试和玩家阅读习惯。
- 新增测试接口：
  - `get_item_compare_summary_for_test(item_id)`

## 新增验证

- `tests/regression/regression_equipment_compare_summary_service.gd`
- 聚焦回归：
  - `FOCUSED_P2_EQUIPMENT_COMPARE_SUMMARY_REGRESSION_OK`

## ROADMAP 更新

- 新增版本：
  - `docs/planning/2026-06-08-dark-tower-2d-arpg-production-roadmap-updated-p2-compare-summary.xlsx`
- P2 完成率更新到 72%。
- T-009 更新为「装备推荐、对比摘要、背包与技能升级可读性」。

## 为后续保留的接口

- 正式装备卡可以直接读取 `score_delta`、`headline`、`stat_deltas`，不需要解析详情文本。
- 背包格子角标可以按 `headline` 或 `score_delta` 做更清晰的升级提示。
- 未来商店、铁匠、仓库、掉落弹窗可以共用 `EquipmentCompareSummaryService`。
- 美术素材接入后，装备图标、稀有边框、属性差异颜色可以围绕同一份 payload 做表现。

## 后续推荐

1. 继续扩展 2-3 个技能节点，但保持最小技能树，不急着做复杂天赋盘。
2. 做 P2「10 分钟刷宝目标检查」服务：记录拾取、换装、升级、楼层推进是否形成连续动机。
3. 把装备详情 UI 拆成更正式的紧凑装备卡布局，为后续图标和正式 UI 皮肤留位。
