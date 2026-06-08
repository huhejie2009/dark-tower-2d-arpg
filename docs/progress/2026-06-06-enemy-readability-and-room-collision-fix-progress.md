# 2026-06-06 敌人动作可读性与塔内厅碰撞修复进度

## 问题修正

这次确认的问题不是“动画状态没有切换”，而是：

- 现有敌人 IMAGE2 帧条动作幅度太小，实机看起来像原地抖动。
- 敌人的攻击、移动、死亡缺少足够明显的运行时表现。
- 新塔内厅背景里的墙体/柱体和真实碰撞盒没有充分对齐。
- 房间边界主要依赖玩家 clamp，缺少真实四边墙碰撞体。

## 已完成

### 敌人动作可读性

修改 `scripts/combat/Enemy2D.gd`：

- 新增 `EnemyAttackArc` 攻击弧提示。
- `run` 动画增加运行时上下 bob 和轻微 sway。
- `attack` 动画增加前冲、压缩和攻击弧，避免只像抖动。
- `death` 动画增加倒伏、压低和淡出趋势。
- 新增测试接口：
  - `get_actor_presentation_state_for_test()`

这不是最终美术动作帧替代品，而是先让当前占位帧条在游戏里“看得懂”。后续仍建议用 IMAGE2 重新生成更夸张、更清晰的攻击/死亡帧。

### 地图碰撞盒

修改 `scripts/app/Game2D.gd`：

- 新增四边墙真实碰撞体：
  - `TopDownNorthWallBody`
  - `TopDownSouthWallBody`
  - `TopDownWestWallBody`
  - `TopDownEastWallBody`
- 柱脚/残墙阻挡改为四个侧边 footprint blocker，避免占用中心战斗通道。
- 保持“高柱视觉不等于整根碰撞体”的原则。
- 新增测试接口：
  - `_get_collision_layout_for_test()`

## 新增/更新测试

- 新增：
  - `tests/regression/regression_enemy_animation_readability_contract.gd`
  - `tests/regression/regression_tower_room_collision_layout.gd`
- 更新：
  - `tests/regression/regression_pseudo_34_safe_spawn_points.gd`

## 验证结果

- 动作与碰撞专项：
  - `NEW_PROJECT_ENEMY_ANIMATION_READABILITY_CONTRACT_OK`
  - `NEW_PROJECT_TOWER_ROOM_COLLISION_LAYOUT_OK`
- 相关回归：
  - `ANIMATION_COLLISION_RELATED_REGRESSION_OK`
- 完整回归：
  - `ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动：
  - `MAIN_HEADLESS_EXIT 0`

## 边界

- 没有清除玩家存档。
- 没有修改存档结构。
- 没有回到旧 3D 项目。
- 没有恢复或接入 POLYGON 资源。
- 本次没有重新生成敌人动作帧，只修运行时表现和碰撞布局。

## 下一步建议

1. 实机试玩，重点看：
   - 敌人攻击弧是否足够明显。
   - 敌人死亡是否有可读的倒伏/淡出。
   - 玩家和敌人是否会被看不见的碰撞卡住。
   - 是否还能穿过明显墙体。
2. 如果动作仍不够理想，再按新美术风格用 IMAGE2 重新生成真正的攻击、跑步、死亡帧条。
3. 后续可以加一个开发调试开关，显示墙体和柱脚碰撞盒，方便继续调地图手感。
