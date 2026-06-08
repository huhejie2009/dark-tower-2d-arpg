# 2026-06-06 俯视生产视角切换进度

## 本次目标

根据试玩反馈，原偏“梦幻西游式斜 45 度/伪 3/4”视角会增加素材制作、脚底锚点、遮挡和碰撞体调试成本。本次将游戏内视角切换为更适合 2D ARPG 长期制作的俯视生产视角。

## 已完成

- `Game2D.gd` 视角契约改为：
  - `ROOM_VISUAL_MODE = "topdown_production"`
  - 摄像机缩放改为 `Vector2(1.0, 1.0)`
  - 视觉纵向压缩改为 `1.0`
- 房间视觉改为俯视矩形：
  - `TopDownFloor`
  - `TopDownTileGrid`
  - `TopDownRoomBorder`
- 墙体和门改为俯视矩形命名：
  - `TopDownNorthWall`
  - `TopDownSouthWall`
  - `TopDownWestWall`
  - `TopDownEastWall`
  - `TopDownNorthDoor`
  - `TopDownSouthDoor`
- 高障碍物改为视觉与碰撞分离：
  - `TopDownColumnVisual`
  - `TopDownColumnShaft`
  - `TopDownColumnFootprintVisual`
  - `TopDownColumnFootprintBody`
- 新增脚底 Y 排序：
  - 玩家、敌人、掉落按 `global_position.y` 更新 `z_index`。
- 保留现有楼层、战斗、掉落、存档和 UI 逻辑。

## 新增与更新测试

- 新增：
  - `res://tests/regression/regression_topdown_production_view_contract.gd`
- 更新：
  - `res://tests/regression/regression_pseudo_34_visual_contract.gd`
  - `res://tests/regression/regression_pseudo_34_room_navigation_contract.gd`
  - `res://tests/regression/regression_floor_clear_door_portal_contract.gd`

说明：部分测试文件名仍带 `pseudo_34`，但内部语义已经切换到 `topdown_production`。后续可以再做一次非行为性的命名整理。

## 设计文档

- `res://docs/design/2026-06-06-topdown-production-view-standard.md`

## 验证结果

- `NEW_PROJECT_TOPDOWN_PRODUCTION_VIEW_CONTRACT_OK`
- `NEW_PROJECT_TOPDOWN_VISUAL_CONTRACT_OK`
- `NEW_PROJECT_TOPDOWN_ROOM_NAVIGATION_CONTRACT_OK`
- `TOPDOWN_VIEW_RELATED_TESTS_OK`
- `TOPDOWN_DOOR_PORTAL_CHECKS_OK`
- `ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动退出码：`0`

## 进程状态

- 验证后没有残留本次 headless 测试进程。
- 检测到一个普通 `Godot.exe --editor` 编辑器进程，未关闭。

## 未触碰内容

- 没有清除玩家存档。
- 没有回到旧 3D 项目。
- 没有恢复或接入 POLYGON 资源。

## 推荐下一步

1. 在编辑器中实机试玩第 1 到第 5 层，重点看柱子前后通行、脚底排序和敌人攻击可读性。
2. 按新视角重新生成 `tower_gatekeeper` Boss 动作条。
3. 后续逐步将旧 `pseudo_34` 函数名和测试文件名迁移为 `topdown`。
