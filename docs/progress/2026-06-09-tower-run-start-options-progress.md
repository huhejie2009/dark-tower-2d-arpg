# 2026-06-09 本次爬塔起始层选择进度

## 本轮目标

继续按 ROADMAP 推进 P2 的稳定可试玩体验。本轮处理试玩反馈中的“每次重新游玩时塔层数异常变高”问题。

本轮不清除玩家存档，不生成代码素材。

## 根因判断

之前已经修复了回归测试污染真实存档的问题，但游戏进入 `Game2D` 时仍然直接读取 `player_data.highest_floor` 作为当前楼层。

这会导致一个体验问题：只要真实存档里的最高层曾经被抬高，玩家点“Enter Tower”就会每次直接进入很高的楼层。最高层本身应该保留为进度记录，但不应该强迫每一次本次爬塔都从最高层开始。

## 已完成

- 新增 `TowerRunStartService`。
- 主城进塔入口拆成两种明确选择：
  - `Enter Tower: Floor 1`：从第 1 层开始本次爬塔。
  - `Challenge Best Floor N`：挑战当前存档记录的最高层。
- `Game2D` 启动时消费一次性起始层请求。
- 如果没有起始层请求，默认从第 1 层开始，避免历史最高层继续制造“莫名其妙跳高层”的体验。
- 请求楼层会被安全限制在 `1..highest_floor` 之间，不会越界进入不存在的异常楼层。

## 新增验证

- `tests/regression/regression_tower_run_start_service.gd`
- `tests/regression/regression_town_tower_start_options.gd`

## 已通过的聚焦验证

- `NEW_PROJECT_TOWER_RUN_START_SERVICE_OK`
- `NEW_PROJECT_TOWN_TOWER_START_OPTIONS_OK`
- `TOWER_RUN_START_OPTIONS_FOCUSED_OK`
- `TOWER_START_RELATED_REGRESSION_OK`
- `ALL_NEW_PROJECT_REGRESSION_OK COUNT 98`
- `HEADLESS_BOOT_EXIT 0`
- `NO_RESIDUAL_GODOT_PROCESS`

## 为后续保留的接口

- 后续可以把 `TowerRunStartService.build_start_options()` 接到更正式的“爬塔入口面板”。
- 后续可以增加章节、难度、门票、楼层预览、推荐战力等字段，而不需要让主城或 `Game2D` 直接解析存档。
- 最高层仍然保留为进度与解锁数据；本次爬塔起点变成独立选择，避免把存档进度和一次性游玩流程绑死。

## 后续推荐

1. 把主城改造成更正式的“塔前准备界面”：角色状态、背包、技能点、起始层选择、挑战按钮集中展示。
2. 在 HUD 增加“本次爬塔”与“历史最高层”的区分显示。
3. 后续如果加入赛季/章节，可以扩展 `TowerRunStartService`，让不同塔区有独立起点和最高层。
