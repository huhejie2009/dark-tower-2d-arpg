# 2026-06-05 伪 3/4 房间结构与绕行进度

## 本轮目标

继续推进 C 方案伪 3/4 俯视视角，让房间从“视觉上像房间”推进到“具备门、厚墙、真实障碍碰撞和敌人绕行保护”的第一版。

## 已完成

- `Game2D.gd`：
  - 新增 `Pseudo34NorthDoor` 与 `Pseudo34SouthDoor`，让房间上下方向有可读门位。
  - 新增 `Pseudo34NorthWall`、`Pseudo34SouthWall`、`Pseudo34WestWall`、`Pseudo34EastWall`，增强房间厚墙感。
  - 将程序化障碍升级为“视觉障碍 + StaticBody2D 碰撞体”。
  - 新增 `Pseudo34ObstacleBody` 与显式命名的 `CollisionShape2D`。
  - 新增 `_get_room_navigation_contract_for_test()`，用于回归测试门、墙、障碍碰撞契约。
- `Enemy2D.gd`：
  - 新增 `_build_chase_velocity()`，统一敌人追击速度计算。
  - 敌人检测到上一帧碰撞时，会混入侧向速度，减少直线追击卡在障碍边的概率。
  - 新增 `_build_chase_velocity_for_test()`，用于验证绕行保护。
- 新增回归测试：
  - `tests/regression/regression_pseudo_34_room_navigation_contract.gd`

## 验证结果

- 单项回归：`NEW_PROJECT_PSEUDO_34_ROOM_NAVIGATION_CONTRACT_OK`
- 完整回归：`ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动：`HEADLESS_EXIT 0`
- Godot 测试残留进程检查：未列出残留 `Godot_v4.6.2-stable_win64` 进程

## 未触碰内容

- 未清除玩家存档。
- 未改动存档 schema。
- 未恢复旧 3D 项目资源。
- 未恢复 POLYGON 资源。
- 未改变传送门清层规则。

## 当前限制

- 门目前是视觉表现，不承担房间切换逻辑。
- 障碍碰撞体是矩形近似，和伪 3/4 视觉多边形不是完全重合。
- 敌人绕行保护是轻量侧步，不是完整寻路系统。

## 下一步建议

1. 为障碍生成安全出生点，避免玩家、敌人或掉落刷在障碍内部。
2. 给门和传送门建立更清晰的关系：清怪后门亮起或传送门出现在门附近。
3. 做房间小型化和多房间节奏，逐步从大竞技场过渡到房间闯关。
4. 给障碍和墙体补更统一的像素风贴图或程序化块面细节。
