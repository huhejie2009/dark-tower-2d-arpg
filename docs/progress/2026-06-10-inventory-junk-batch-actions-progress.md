# 背包废品批量处理前置进度

日期：2026-06-10  
路线图对应：IE-090 / P2.2 背包装备窗口，P3 商人/铁匠前置接口

## 本轮完成

- 新增纯数据服务 `InventoryItemActionService`。
- 新增废品处理预览接口：
  - `build_junk_action_preview(player_data, "sell")`
  - `build_junk_action_preview(player_data, "salvage")`
- 新增废品处理执行接口：
  - `process_junk_action(player_data, "sell")`
  - `process_junk_action(player_data, "salvage")`
- 批量处理规则：
  - 只处理 `binding_flags.junk == true` 的物品。
  - 自动跳过锁定物品。
  - 自动跳过收藏物品。
  - 自动跳过已装备物品。
  - 自动跳过 `sellable == false` 的物品。
- 背包窗口新增批量入口：
  - `SellJunkButton`
  - `SalvageJunkButton`
- UI 操作通过服务层执行，不把商人/铁匠规则写死在窗口里。

## 数据与后续接口

- 出售废品会把收益写入背包中的 `gold` 堆叠。
- 分解废品会把收益写入背包中的 `crystal_shard` 堆叠。
- 返回结果包含：
  - `processed_item_ids`
  - `protected_item_ids`
  - `gold_gain`
  - `crystal_gain`
  - `summary_text`
- 后续商人窗口可以直接复用 `sell` 模式。
- 后续铁匠窗口可以直接复用 `salvage` 模式。
- 后续确认弹窗可以直接使用 `build_junk_action_preview()` 的摘要与候选列表。

## 新增测试

- `tests/regression/regression_inventory_junk_batch_actions.gd`

## 验证结果

目标回归已通过：

- `NEW_PROJECT_INVENTORY_JUNK_BATCH_ACTIONS_OK`
- `NEW_PROJECT_INVENTORY_FLAG_FILTERS_UI_OK`
- `NEW_PROJECT_INVENTORY_TOOLS_CONTRACT_OK`
- `NEW_PROJECT_INVENTORY_QUERY_SERVICE_OK`
- `NEW_PROJECT_INVENTORY_CAPACITY_RULES_OK`
- `NEW_PROJECT_INVENTORY_WINDOW_RESPONSIVE_BOUNDS_OK`
- `NEW_PROJECT_INVENTORY_EQUIPMENT_ACTIONS_OK`
- `FOCUSED_INVENTORY_JUNK_ACTIONS_OK`

Godot headless 退出时仍会出现已知的 `ObjectDB instances leaked` / `resources still in use` 清理警告；目标测试退出码为 0，按非阻断处理。

## 后续建议

1. 给 `Sell Junk` / `Salvage` 增加确认弹窗，显示将处理的件数、保护件数和收益。
2. 在主城制作商人/铁匠入口时复用 `InventoryItemActionService`，不要重新实现处理规则。
3. 做一轮背包窗口截图 QA，检查新增按钮在 1280x720、1600x900、1920x1080 下是否拥挤。
