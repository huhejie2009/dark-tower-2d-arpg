# 装备槽迁移与穿脱安全进度

日期：2026-06-10  
路线图对应：IE-020、IE-030，P2.1 数据稳定层

## 本轮完成

- 将装备槽从旧的 `ring` 单槽升级为 `ring_1` / `ring_2` 双戒指槽。
- 新增 `EquipmentDataService.normalize_equipped_items()`，统一装备槽归一化。
- 新增 `EquipmentDataService.get_equippable_slots()` 和 `resolve_equip_slot()`，让 UI、推荐、对比和穿戴逻辑共享同一套槽位解析规则。
- 旧存档中的 `equipped_items.ring` 会在玩家数据归一化时迁移到 `ring_1`，`ring_2` 自动补空。
- 新掉落如果仍使用 `equipment.slot = "ring"`，会自动选择空的 `ring_1` 或 `ring_2`；两个戒指槽都满时默认替换 `ring_1`。
- `equip_item()` 现在会返回 `replaced_item_id`，方便后续 UI 明确显示“将替换哪件装备”。
- 装备替换失败时返回原始玩家数据副本，不改变背包和装备槽。

## 新增测试

- `tests/regression/regression_equipment_slot_migration.gd`
- `tests/regression/regression_inventory_equipment_actions.gd`

## 验证结果

已验证：

- `NEW_PROJECT_EQUIPMENT_SLOT_MIGRATION_OK`
- `NEW_PROJECT_INVENTORY_EQUIPMENT_ACTIONS_OK`
- `NEW_PROJECT_EQUIPMENT_CAN_EQUIP_OK`
- `NEW_PROJECT_EQUIPMENT_UNEQUIP_AND_STATS_OK`
- `INVENTORY_EQUIPMENT_TARGETED_REGRESSION_OK`

目标回归范围包括：

- 装备可穿戴规则
- 装备卸下与属性汇总
- 装备评分
- 装备推荐
- 装备对比摘要
- 背包容量规则
- 背包装备窗口操作
- 物品视觉元数据
- 主城塔前准备推荐与摘要

Godot headless 退出时仍会出现已知的 `ObjectDB instances leaked` / `resources still in use` 清理警告；本轮目标测试退出码为 0，按非阻断处理。

## 后续建议

下一步继续 IE-010 / IE-040：

- 补齐物品实例契约：`binding_flags`、`icon_id`、`source_tags`。
- 将装备对比摘要进一步升级为“1 到 3 条解释原因”，让 UI 能直接展示推荐理由。
- 给背包筛选/排序新增纯数据查询服务，避免 UI 直接处理复杂过滤逻辑。

