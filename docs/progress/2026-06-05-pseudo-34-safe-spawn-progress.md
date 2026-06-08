# 2026-06-05 伪 3/4 安全出生点进度

## 本轮目标

继续推进 C 方案伪 3/4 房间改造，为玩家、敌人、掉落和传送门加入安全出生点保护，避免实体刷在新增障碍碰撞体内部。

## 已完成

- `Game2D.gd`：
  - 新增 `solid_spawn_blockers`，记录伪 3/4 障碍碰撞矩形。
  - 新增 `_is_position_blocked()`，用实体半径扩张障碍矩形后判断位置是否被阻挡。
  - 新增 `_find_safe_spawn_position()`，当目标点被障碍阻挡时，按固定方向和距离寻找最近安全点。
  - 玩家出生和进下一层回中点现在会走安全点校正。
  - 敌人出生点现在会走安全点校正。
  - 掉落生成点现在会走安全点校正。
  - 传送门生成点现在会走安全点校正。
  - 新增测试入口：
    - `_is_position_blocked_for_test()`
    - `_find_safe_spawn_position_for_test()`
    - `_spawn_portal_for_test()`
- 新增回归测试：
  - `tests/regression/regression_pseudo_34_safe_spawn_points.gd`

## 调试记录

- 初次运行安全出生点测试时出现超时。
- 根因是测试里误用了 `root.get_nodes_in_group("enemies")`，`root` 是窗口根节点，不是 `SceneTree`。
- 修正为 `get_nodes_in_group("enemies")` 后，测试正常退出并通过。

## 验证结果

- 单项回归：`NEW_PROJECT_PSEUDO_34_SAFE_SPAWN_POINTS_OK`
- 完整回归：`ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动：`HEADLESS_EXIT 0`
- Godot 测试残留进程检查：未列出残留 `Godot_v4.6.2-stable_win64` 进程

## 未触碰内容

- 未清除玩家存档。
- 未改动存档 schema。
- 未恢复旧 3D 项目资源。
- 未恢复 POLYGON 资源。
- 未改变楼层奖励、背包和装备数据。

## 当前限制

- 安全点搜索是轻量固定方向搜索，不是完整空间采样。
- 障碍碰撞体仍是矩形近似。
- 掉落被推离障碍时可能与死亡位置略有偏移，后续需要增加短距离落地动画或吸附反馈。

## 下一步建议

1. 让清怪后的传送门出现在门附近，并让门有点亮反馈。
2. 逐步把大竞技场拆成更小的房间节奏。
3. 增加障碍周围的敌人出生分布规则，避免所有怪物被推到同一侧。
4. 给掉落增加轻微弹跳/吸附表现，掩盖安全点校正带来的位置微调。
