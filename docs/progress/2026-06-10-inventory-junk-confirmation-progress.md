# 废品批量处理确认弹窗进度

日期：2026-06-10  
路线图对应：IE-090 / P2.2 背包装备窗口，P3 商人/铁匠交互前置

## 本轮完成

- 背包窗口新增 `JunkActionConfirmDialog`。
- `Sell Junk` 与 `Salvage` 不再立即处理物品，而是先生成待确认预览。
- 新增待确认接口：
  - `get_pending_junk_action_preview_for_test()`
  - `confirm_pending_junk_action_for_test()`
- 确认文本包含：
  - 操作类型
  - 将处理的废品数量
  - 被保护的物品数量
  - 预计获得的金币或材料
  - 锁定、收藏、已装备、不可出售物品会被保护的说明
- 确认后才调用 `InventoryItemActionService.process_junk_action()`，保持 UI 与数据规则分离。

## 设计收益

- 降低玩家误点批量出售/分解的风险。
- 后续商人出售、铁匠分解可以复用相同的预览与确认流程。
- 确认弹窗使用文字信息作为主反馈，不依赖颜色，符合当前 UI 可读性验收方向。
- 继续保留正式图标素材接口，没有新增代码生成素材。

## 新增测试

- `tests/regression/regression_inventory_junk_action_confirmation.gd`

## 验证结果

目标回归已通过：

- `NEW_PROJECT_INVENTORY_JUNK_ACTION_CONFIRMATION_OK`
- `NEW_PROJECT_INVENTORY_JUNK_BATCH_ACTIONS_OK`
- `NEW_PROJECT_INVENTORY_FLAG_FILTERS_UI_OK`
- `NEW_PROJECT_INVENTORY_TOOLS_CONTRACT_OK`
- `NEW_PROJECT_INVENTORY_WINDOW_RESPONSIVE_BOUNDS_OK`
- `NEW_PROJECT_UI_VISUAL_QA_LAYOUT_CONTRACT_OK`
- `NEW_PROJECT_DARK_ARPG_UI_THEME_CONTRACT_OK`
- `FOCUSED_INVENTORY_CONFIRMATION_LAYOUT_OK`

Godot headless 退出时仍会出现已知的 `ObjectDB instances leaked` / `resources still in use` 清理警告；目标测试退出码为 0，按非阻断处理。

## 后续建议

1. 做主城商人/铁匠入口，复用本轮确认流程。
2. 给确认弹窗补正式暗黑 UI 视觉细节和图标素材位。
3. 做一轮实机截图 QA，检查弹窗层级、背包按钮密度和 1280x720 下的阅读空间。
