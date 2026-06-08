# 2026-06-09 背包筛选选中态进度

## 本轮目标

继续按照 ROADMAP 推进第一版稳定可试玩 UI。背包窗口已有 All / Equip / Mat 筛选，但按钮本身没有选中态，玩家需要从物品变化反推当前筛选模式。本轮补上筛选按钮状态同步。

本轮未清理玩家存档，未回到旧 3D/POLYGON 项目，未新增代码生成素材。

## 已完成

- 背包筛选按钮启用 `toggle_mode`。
- 新增 `filter_buttons` 状态映射。
- 新增 `_sync_filter_button_states()`，统一同步 All / Equip / Mat 的当前选中态。
- `set_filter_mode()` 会同步按钮状态并刷新物品网格。
- 初始打开背包时默认高亮 All。
- 切到 Mat / Equip 时旧筛选按钮会取消选中，新筛选按钮会选中。

## 留给后续的接口

后续接入正式暗黑 ARPG UI 主题时，可以基于 `filter_buttons` 和 `_sync_filter_button_states()` 扩展：

- 当前筛选高亮边框。
- 当前筛选背景色。
- 筛选按钮 tooltip。
- 键盘/手柄焦点态。

## 验证

扩展回归：

- `NEW_PROJECT_INVENTORY_TOOLS_CONTRACT_OK`

相邻验证：

- `NEW_PROJECT_INVENTORY_PAUSES_COMBAT_OK`
- `NEW_PROJECT_INVENTORY_WINDOW_RESPONSIVE_BOUNDS_OK`
- `NEW_PROJECT_INVENTORY_EQUIPMENT_ACTION_HINTS_OK`
- `NEW_PROJECT_INVENTORY_EQUIPMENT_SELECTION_ACTIONS_OK`
- `NEW_PROJECT_INVENTORY_RECOMMENDATION_TAGS_OK`
