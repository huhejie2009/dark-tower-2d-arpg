# 2026-06-11 商人买回池存档桥接进度

## 本轮目标

继续按功能底座优先推进，给上一轮 `VendorTransactionService` 的买回池增加存档槽持久化能力。当前不做商人 UI，只保证后续正式商店窗口可以读取和写入可靠数据。

## 已完成内容

- `SaveSchema` 新增 `vendor_buyback` 字段。
- 旧存档缺失 `vendor_buyback` 时会规范化为空数组。
- `SaveManager` 新增 `get_active_vendor_buyback()`。
- `SaveManager` 新增 `save_active_vendor_buyback()`。
- 卖出后的买回池可以写入当前存档槽。
- 重新读取存档后可以买回物品，并保留原始装备数据。
- 买回完成后会清空对应买回池条目。

## 新增回归

- `regression_vendor_buyback_save_bridge.gd`

## 验收标准

- 买回池保存后可重新读取。
- 买回池条目保留 `item_id` 与原始物品数据。
- 买回池可直接供 `VendorTransactionService.buyback_item()` 使用。
- 买回后对应条目从买回池移除。
- 旧存档缺失字段时不报错，自动使用空买回池。

## 后续建议

1. 将 `InventoryItemActionService.process_junk_action()` 的批量卖废品接入买回池。
2. 为买回池增加容量、排序和过期规则。
3. 后续正式商人窗口只负责展示和调用服务，不再写交易规则。
