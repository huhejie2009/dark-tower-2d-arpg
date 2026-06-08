# 2026-06-07 装备评分服务化进度

## 对应 ROADMAP

- 阶段：P1 可试玩 UI 与装备闭环
- 任务：T-002 装备评分服务化

## 本轮目标

把背包窗口中临时维护的装备分数、已装备识别、同槽位更强装备判断迁移到 `EquipmentDataService`，为后续掉落提示、装备推荐、自动排序共用同一套权威规则。

## 已完成

- `EquipmentDataService` 新增：
  - `get_equipment_score(equipment)`
  - `get_item_score(player_data, item_id)`
  - `is_equipped_item(player_data, item_id)`
  - `is_upgrade_candidate(player_data, item_id)`
- `InventoryEquipmentWindow` 已改为调用 `EquipmentDataService`：
  - 装备详情 `Score`
  - 背包分数排序
  - 已装备 `E` 标识
  - 更强装备 `+` 标识
- 保留现有背包窗口测试接口，外部行为不变。

## 回归覆盖

新增：

- `tests/regression/regression_equipment_score_service.gd`

已验证：

- `NEW_PROJECT_EQUIPMENT_SCORE_SERVICE_OK`
- `FOCUSED_EQUIPMENT_SCORE_SERVICE_REGRESSION_OK`

## ROADMAP 更新

原工作簿当前被占用，无法原地覆盖；已另存更新版：

- `docs/planning/2026-06-07-dark-tower-2d-arpg-production-roadmap-updated-p1-score-service.xlsx`

更新内容：

- T-002 状态改为 `已完成`。
- P1 完成率更新为 `45%`。

## 下一步建议

继续执行 P1 / T-003：

- 战斗内掉落提示。
- 拾取装备时显示稀有度、槽位、分数、是否更强。
- Boss 奖励使用独立提示。
