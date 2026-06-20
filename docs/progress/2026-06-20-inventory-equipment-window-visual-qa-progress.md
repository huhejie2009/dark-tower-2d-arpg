# 背包与装备窗口实机视觉 QA 进度

日期：2026-06-20

## 本轮目标

- 先把背包与装备窗口做一次实机截图检查，优先修复影响读懂装备、资源和详情文本的问题。
- 保持数据接口稳定，不清空玩家存档，不改变装备/背包存档结构。

## 已完成

- 新增背包/装备窗口截图工具：
  - `res://tools/qa_capture_inventory_window_screenshot.gd`
  - 输出：`docs/qa/screenshots/inventory_equipment_window_1280x720.png`
- 截图工具已纳入 headless guard 回归，避免无渲染模式下截图卡住。
- 修复装备槽 UI 汉化：
  - `gloves` 显示为 `手套`
  - `ring_1` 显示为 `戒指 1`
  - `ring_2` 显示为 `戒指 2`
- 修复背包格子短标签：
  - 装备显示中文部位短标签，例如 `武器`、`护甲`、`手套`、`戒1`、`戒2`
  - 金币和材料显示中文含义加数量，例如 `金 / 240`、`晶 / 18`
- 右侧物品详情改为独立滚动区域：
  - 长装备说明和对比文本不再把按钮和底部内容挤出窗口。
  - 保留后续正式图标、更多词缀、套装说明的扩展空间。

## 新增/更新回归

- `regression_equipment_paper_doll_layout.gd`
  - 验证装备槽按钮不再泄漏英文 `Gloves` / `Ring`。
- `regression_inventory_item_visual_metadata.gd`
  - 验证装备格子使用中文部位标签。
  - 验证金币/材料格子同时显示物品含义和数量。
- `regression_ui_visual_qa_layout_contract.gd`
  - 验证物品详情存在独立滚动区。
  - 验证 1280x720 下详情滚动区有最小阅读高度。
- `regression_qa_screenshot_tools_headless_guard.gd`
  - 验证背包截图工具不会在 headless 下误运行。

## 实机 QA 截图

- `docs/qa/screenshots/inventory_equipment_window_1280x720.png`

截图结论：

- 背包格子现在能直接看出金币、材料、装备部位。
- 装备栏槽位全部中文化。
- 物品详情区出现滚动条，长文本不会继续溢出窗口。

## 后续建议

- 下一轮继续做“功能性优先”的打磨：
  - 背包/装备右键快速操作与按钮状态提示。
  - 装备对比摘要进一步压缩成更清楚的收益/损失行。
  - 资源和装备格子接入正式图标资源接口，避免继续依赖纯文字格子。
