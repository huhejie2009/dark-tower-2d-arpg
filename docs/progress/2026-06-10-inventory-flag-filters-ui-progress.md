# 背包标记筛选 UI 进度

日期：2026-06-10  
路线图对应：IE-070、IE-080，P2.2 背包装备窗口体验

## 本轮完成

- 背包工具栏新增筛选入口：
  - `Upg`：只看推荐升级装备
  - `Lock`：只看锁定物品
  - `Fav`：只看收藏物品
  - `Junk`：只看废品标记物品
- 选中物品操作区新增：
  - `Fav` / `Unfav`
  - `Junk` / `Unjunk`
- `toggle_item_lock()`、`toggle_item_favorite()`、`toggle_item_junk()` 统一写入 `binding_flags`。
- 旧的顶层 `locked` 字段继续同步写入，用于兼容现有显示和旧逻辑。
- `InventoryEquipmentWindow.get_visible_item_ids()` 继续走 `InventoryQueryService`，UI 不再自己维护复杂筛选规则。

## 新增测试

- `tests/regression/regression_inventory_flag_filters_ui.gd`

## 验证结果

已通过目标回归：

- `NEW_PROJECT_INVENTORY_FLAG_FILTERS_UI_OK`
- `NEW_PROJECT_INVENTORY_TOOLS_CONTRACT_OK`
- `NEW_PROJECT_INVENTORY_QUERY_SERVICE_OK`
- `NEW_PROJECT_INVENTORY_WINDOW_RESPONSIVE_BOUNDS_OK`

Godot headless 退出时仍会出现已知的 `ObjectDB instances leaked` / `resources still in use` 清理警告；目标测试退出码为 0，按非阻断处理。

## 后续建议

下一步可以进入批量处理和城镇整理前置：

- 批量出售/分解废品前，先做纯数据服务校验，避免误处理锁定或收藏物品。
- 商人、铁匠和仓库窗口直接复用 `InventoryQueryService` 与 `binding_flags`。
- UI 后续可把文字按钮替换为正式图标资源，但不要改变 `binding_flags` 数据接口。

