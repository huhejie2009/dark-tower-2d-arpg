# 2026-06-05 玩家死亡表现读取 IMAGE2 动画时长进度

## 目标

继续保留 IMAGE2 素材接口，让玩家死亡表现窗口不再只依赖固定短延迟，而是优先读取玩家 SpriteSheet manifest 中 `death` 动画的帧段和 fps。

## 已完成

- `Player2D.gd` 新增死亡动画时长计算：
  - 仅当 manifest `enabled = true` 且存在 `animations.death` 时生效。
  - 使用 `from`、`to`、`fps` 计算持续时间。
  - `fps <= 0` 或缺少 `death` 动画时返回 0。
- `Player2D.gd` 新增测试接口 `get_death_animation_duration_for_test()`。
- `Game2D.gd` 的死亡表现窗口现在按优先级取时长：
  - 测试 override。
  - 玩家 manifest 的 `death` 动画时长。
  - 默认短延迟 `DEFAULT_DEATH_PRESENTATION_DELAY`。
- `Game2D.gd` 新增测试接口 `_get_death_presentation_delay_for_test()`。
- 新增回归测试 `regression_player_death_presentation_uses_manifest_duration.gd`，覆盖：
  - 玩家 manifest 的 death 动画时长会被读取。
  - 死亡结算不会在 death 动画时长结束前出现。
  - death 动画窗口结束后仍会进入原死亡结算。

## 验证结果

- 单项回归：
  - `NEW_PROJECT_PLAYER_DEATH_PRESENTATION_USES_MANIFEST_DURATION_OK`
  - `NEW_PROJECT_PLAYER_DEATH_PRESENTATION_DELAY_OK`
  - `NEW_PROJECT_DEATH_SETTLEMENT_CONTRACT_OK`
- 完整回归：`ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动：`HEADLESS_EXIT 0`
- 最终进程检查无 Godot 残留进程输出。

## 未触碰范围

- 没有清除玩家存档。
- 没有改动存档结构。
- 没有回到旧 3D 项目。
- 没有恢复 POLYGON 资源。
- 没有导入正式 IMAGE2 图片素材。

## 后续建议

1. 接入第一套 IMAGE2 玩家 SpriteSheet，实机验证 idle/run/attack/death。
2. 为死亡表现期间增加敌人冻结、镜头轻微收束或慢动作反馈。
3. 给死亡结算 UI 增加更清晰的按钮状态与音效反馈。
