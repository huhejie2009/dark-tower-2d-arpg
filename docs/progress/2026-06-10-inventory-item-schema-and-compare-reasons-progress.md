# 物品实例契约与装备对比解释进度

日期：2026-06-10  
路线图对应：IE-010、IE-040，P2.1 数据稳定层

## 本轮完成

- 新增 `InventoryItemSchemaService`，集中归一化背包物品实例字段。
- `InventoryDataService.add_item()` 现在会为进入背包的物品补齐交付级字段：
  - `instance_id`
  - `item_power`
  - `binding_flags`
  - `icon_id`
  - `source_tags`
- `binding_flags` 统一包含：
  - `locked`
  - `favorite`
  - `junk`
  - `sellable`
- `icon_id` 作为正式素材接口保留，装备默认格式为 `equipment.<slot>.<rarity>`，非装备默认格式为 `item.<type>`。
- `source_tags` 统一记录类型、来源、品质、装备槽、稀有度和职业池，后续仓库、商人、铁匠、掉落过滤可直接复用。
- `EquipmentCompareSummaryService` 增加：
  - `reason_lines`
  - `primary_reason`
- 对比摘要现在会输出 1 到 3 条可直接给 UI 展示的解释，例如评分变化和关键词缀变化。

## 新增测试

- `tests/regression/regression_inventory_item_schema.gd`
- `tests/regression/regression_item_compare_summary.gd`

## 验证结果

已通过目标回归：

- `NEW_PROJECT_INVENTORY_ITEM_SCHEMA_OK`
- `NEW_PROJECT_ITEM_COMPARE_SUMMARY_OK`
- `NEW_PROJECT_EQUIPMENT_COMPARE_SUMMARY_SERVICE_OK`
- `INVENTORY_ITEM_SCHEMA_TARGETED_REGRESSION_OK`

目标回归覆盖：

- 背包容量规则
- 物品视觉元数据
- 背包装备操作提示
- 背包装备选择与使用
- 装备推荐
- 装备对比文本
- 掉落通知推荐标签
- 普通拾取进入背包
- Boss 奖励进入背包

Godot headless 退出时仍会出现已知的 `ObjectDB instances leaked` / `resources still in use` 清理警告；目标测试退出码为 0，按非阻断处理。

## 后续建议

下一步可以进入 IE-080 的前置工作：

- 做 `InventoryQueryService`，把筛选、排序、搜索从 UI 中抽出来。
- 让 UI 背包窗口只消费查询结果和元数据，减少后续仓库/商人/铁匠重复实现。
- 基于 `binding_flags` 接入更完整的锁定、收藏、废品批量处理逻辑。

