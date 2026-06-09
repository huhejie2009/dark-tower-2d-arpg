# 背包查询服务进度

日期：2026-06-10  
路线图对应：IE-080 前置工作，服务于 P2.2 背包装备窗口和 P3 仓库/商人/铁匠

## 本轮完成

- 新增 `InventoryQueryService`，把背包筛选和排序从 UI 窗口中抽到数据服务层。
- `InventoryEquipmentWindow.get_visible_item_ids()` 改为调用查询服务，保留现有 UI 对外方法。
- 查询服务支持筛选：
  - `all`
  - `equipment`
  - `material`
  - `upgrade`
  - `locked`
  - `favorite`
  - `junk`
- 查询服务支持排序：
  - `type`
  - `power`
  - `name`
- 排序规则保留“锁定物品优先”，减少玩家误操作风险。
- `InventoryDataService.add_item()` 现在会透传 `binding_flags`、`icon_id`、`source_tags`、`item_power`，避免进入背包时丢掉交付级物品契约字段。

## 新增测试

- `tests/regression/regression_inventory_query_service.gd`

## 验证结果

已通过目标回归：

- `NEW_PROJECT_INVENTORY_QUERY_SERVICE_OK`
- `NEW_PROJECT_INVENTORY_TOOLS_CONTRACT_OK`
- `NEW_PROJECT_INVENTORY_ITEM_SCHEMA_OK`
- `NEW_PROJECT_INVENTORY_ITEM_VISUAL_METADATA_OK`
- `NEW_PROJECT_INVENTORY_EQUIPMENT_ACTION_HINTS_OK`
- `NEW_PROJECT_INVENTORY_EQUIPMENT_SELECTION_ACTIONS_OK`
- `NEW_PROJECT_INVENTORY_CAPACITY_RULES_OK`
- `NEW_PROJECT_EQUIPMENT_COMPARE_SUMMARY_SERVICE_OK`
- `NEW_PROJECT_ITEM_COMPARE_SUMMARY_OK`
- `NEW_PROJECT_TOWN_PREP_RECOMMENDATION_SERVICE_OK`
- `NEW_PROJECT_TOWN_PREP_SUMMARY_SERVICE_OK`
- `INVENTORY_QUERY_TARGETED_REGRESSION_OK`

Godot headless 退出时仍会出现已知的 `ObjectDB instances leaked` / `resources still in use` 清理警告；目标测试退出码为 0，按非阻断处理。

## 后续建议

下一步可以把 UI 控件补齐到查询服务已有能力：

- 增加 `upgrade`、`locked`、`favorite`、`junk` 筛选入口。
- 基于 `binding_flags` 补完整收藏、废品标记、批量处理。
- 后续仓库、商人、铁匠窗口直接复用 `InventoryQueryService`，不要再各自实现筛选排序。

