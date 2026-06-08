# 2026-06-05 敌人死亡动画碰撞关闭进度

## 目标

敌人进入死亡动画并延迟释放期间，不再阻挡玩家移动或后续战斗判定，避免“尸体还在挡路”的手感问题。

## 已完成

- `Enemy2D.gd` 中为敌人碰撞体补充稳定节点名，便于回归测试和后续调试定位。
- `Enemy2D.gd` 新增死亡时关闭所有 `CollisionShape2D` 的逻辑。
- 敌人受到致命伤害后，现在会先进入死亡状态、触发死亡动画、关闭碰撞，再停止物理处理、发出死亡信号并按动画时长延迟释放。
- 新增回归测试 `regression_enemy_death_disables_collision.gd`，覆盖“死亡动画等待期间碰撞体必须禁用”。

## 验证结果

- 单项回归：`NEW_PROJECT_ENEMY_DEATH_DISABLES_COLLISION_OK`
- 完整回归：`ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动：`HEADLESS_EXIT 0`
- 启动验证后未发现残留 Godot 测试进程输出。

## 未触碰范围

- 没有清除或迁移玩家存档。
- 没有改动旧 3D 项目或恢复 POLYGON 资源。
- 没有导入正式 IMAGE2 人物素材，只继续保留并增强 2D SpriteSheet 素材接口。

## 后续建议

- 玩家死亡表现窗口与结算节奏。
- 首个 IMAGE2 角色 SpriteSheet 实际接入验证。
- 敌人死亡动画的特效与音效表现。
- 如后续加入攻击盒或受击盒，可继续补充死亡期间禁用这些判定的回归。
