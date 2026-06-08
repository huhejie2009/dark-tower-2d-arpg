# 2026-06-06 敌人动画状态播放修复进度

## 问题

试玩中敌人看起来没有静止、移动、攻击、死亡动画。

排查后确认，现有敌人 spritesheet 已经是 20 帧横向帧条，并且 manifest 中已配置：

- `idle`
- `run`
- `attack`
- `death`

主要问题在运行时代码：

- 每帧重复设置同一个动画时，会把帧重置回起始帧。
- 攻击动画下一帧会被 idle 覆盖，导致攻击表现看不到。
- 敌人死亡后关闭 physics，死亡动画没有正常继续推进。

## 已完成

- 修改 `scripts/combat/Enemy2D.gd`
  - 同一动画重复设置时不再重置帧。
  - `attack` 作为一次性动画，播放完之前不被 idle/run 打断。
  - `death` 作为一次性动画，死亡后继续由 `_process` 推进帧。
  - 保留 idle/run 循环播放。
- 新增回归测试：
  - `tests/regression/regression_enemy_animation_state_playback.gd`
- 更新旧 spritesheet 状态测试：
  - `tests/regression/regression_actor_spritesheet_texture_and_state.gd`
  - 敌人攻击动画现在必须先播放完，不能立刻回 idle。

## 验证结果

- 新增测试：
  - `NEW_PROJECT_ENEMY_ANIMATION_STATE_PLAYBACK_OK`
- 动画相关回归：
  - `ENEMY_ANIMATION_RELATED_REGRESSION_OK`
- 完整回归：
  - `ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动：
  - `MAIN_HEADLESS_EXIT 0`

## 边界

- 没有清除玩家存档。
- 没有修改存档结构。
- 没有重新生成敌人素材。
- 没有回到旧 3D 项目。
- 没有恢复或接入 POLYGON 资源。

## 后续建议

1. 实机试玩确认三个敌人类型的攻击和死亡是否足够明显。
2. 如果动作幅度仍然不够，再用 IMAGE2 重新生成更夸张的敌人动作帧条。
3. 玩家动画状态机后续也可以按敌人这套一次性动画规则统一，特别是攻击和死亡。
