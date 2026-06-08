# 2026-06-05 菜单焦点与取消键进度

## 本轮目标

继续推进“第一版可稳定试玩 UI 与稳定性增强”，补齐暂停、背包和死亡结算之间的键盘焦点与取消键行为，减少玩家在覆盖层 UI 中卡住或误操作的概率。

## 已完成

- 暂停菜单打开后，焦点会自动落到 `ResumeButton`。
- 死亡结算打开后，焦点会自动落到 `DeathReturnTownButton`。
- `Esc` 输入改为统一取消处理：
  - 死亡结算已激活时，不允许用 `Esc` 关闭结算。
  - 背包/装备窗口打开时，`Esc` 优先关闭背包/装备窗口。
  - 没有背包窗口拦截时，`Esc` 才切换暂停菜单。
- 新增测试辅助入口：
  - `_toggle_pause_for_test()`
  - `_show_death_settlement_for_test()`
  - `_handle_cancel_for_test()`
- 新增回归测试 `tests/regression/regression_menu_focus_and_cancel.gd`。

## 验证结果

- 单项回归：`NEW_PROJECT_MENU_FOCUS_AND_CANCEL_OK`
- 完整回归：`ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动：`HEADLESS_EXIT 0`
- Godot 测试残留进程检查：未列出残留 `Godot_v4.6.2-stable_win64` 进程

## 未触碰内容

- 未清除玩家存档。
- 未改动存档 schema。
- 未恢复旧 3D 项目资源。
- 未恢复 POLYGON 资源。

## 下一步建议

1. 为暂停/死亡结算按钮补视觉选中态和禁用态。
2. 为背包/装备窗口补键盘焦点路径，支持不用鼠标完成查看、排序和装备穿脱。
3. 为 Boss 技能警示、投射物和精英词缀补更明显的 2D 视觉反馈。
