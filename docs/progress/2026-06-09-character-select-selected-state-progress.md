# 2026-06-09 角色选择选中态修复进度

## 本轮目标

继续按照 ROADMAP 推进第一版稳定可试玩 UI。上一轮已经为角色选择界面补充当前槽位和职业文字反馈，本轮继续补上按钮级选中态，让玩家不需要只靠阅读文字确认选择。

本轮未清理玩家存档，未回到旧 3D/POLYGON 项目，未新增代码生成素材。

## 已完成

- 存档槽按钮启用 `toggle_mode`。
- 职业按钮启用 `toggle_mode`。
- 新增 `slot_buttons` 与 `class_buttons` 状态映射，后续正式 UI 主题可直接读取或扩展。
- 新增 `_sync_button_selected_states()`，统一同步当前选中槽位和职业按钮状态。
- 点击空槽位后，旧槽位按钮会取消选中，新槽位按钮会选中。
- 点击职业后，旧职业按钮会取消选中，新职业按钮会选中。

## 验证

扩展回归：

- `NEW_PROJECT_SAVE_SLOTS_UI_CONTRACT_OK`

相邻验证：

- `NEW_PROJECT_CHARACTER_CREATE_OK`
- `NEW_PROJECT_SCENE_BOOT_ALL_OK`

## 后续接口说明

后续接入正式暗黑 ARPG UI 主题时，可以在 `_sync_button_selected_states()` 中继续附加：

- 选中边框颜色。
- 选中背景色。
- 鼠标悬停提示。
- 键盘/手柄焦点状态。

这一步先保留 Godot 原生按钮选中态，避免在没有正式 UI 主题前堆临时美术或代码生成素材。
