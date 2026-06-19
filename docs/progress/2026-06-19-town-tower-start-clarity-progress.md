# 2026-06-19 主城进塔楼层说明进度

## 目标

解决试玩中“为什么每次打开游戏塔层数会变得很高”的理解问题。玩家需要明确区分：

- `Floor 1`：从第 1 层开始新的爬塔尝试。
- `Best Floor`：从存档中的最高已解锁楼层开始挑战。
- `highest_floor`：存档进度，不代表游戏每次强制从高层开始。

## 已完成

- `TowerRunStartService.build_start_options()` 增加开始说明：
  - `fresh_description`
  - `best_description`
  - `highest_floor_explanation`
  - `explanation_text`
- `TownPrepSummaryService` 的整备栏起始说明加入 `highest_floor` 解释。
- 主城增加 `get_tower_start_snapshot_for_test()`，后续 Godot AI / 回归可直接读取进塔选项和说明文案。
- 提升 `TownStartSummary` 高度，避免三行说明拥挤。
- 更新主城与起始楼层回归，要求说明文案持续存在。

## 验收

- 主城仍保留“从第 1 层进入”和“挑战最高层”两个入口。
- 最高层按钮显示保存的最高层数字。
- 整备栏说明明确提到 `highest_floor` 是存档进度。
- 起始楼层服务仍保持一次性消费请求，不会污染下一次进塔。

## 验证

- 红测先失败，失败点为缺少开始说明和主城开始快照。
- 聚焦回归已通过：`FOCUSED_TOWN_TOWER_START_CLARITY_OK`。
