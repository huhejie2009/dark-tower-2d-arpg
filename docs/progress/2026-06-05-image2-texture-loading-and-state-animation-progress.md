# 2026-06-05 IMAGE2 贴图加载与状态动画进度

## 本轮目标

继续推进 IMAGE2 素材接入准备工作，让 `ActorSprite` 能从 manifest 的 `sprite_sheet_path` 加载贴图，并让玩家/敌人根据移动和攻击状态切换 `idle`、`run`、`attack` 动画。

## 已完成

- `Player2D.gd`：
  - `apply_visual_asset_manifest()` 会尝试读取 `sprite_sheet_path`。
  - 贴图存在时，会通过 `ImageTexture.create_from_image()` 设置到 `ActorSprite.texture`。
  - 新增 `update_actor_animation_state()`：
    - 攻击优先切到 `attack`
    - 移动时切到 `run`
    - 静止时切到 `idle`
  - `_physics_process()` 中会根据当前移动和攻击冷却状态更新动画。
  - 新增 `update_actor_animation_state_for_test()`。
- `Enemy2D.gd`：
  - 实现与玩家一致的 manifest 贴图加载。
  - 追击时切到 `run`。
  - 出手时切到 `attack`。
  - 近身停下时切到 `idle`。
  - 新增 `update_actor_animation_state_for_test()`。
- `Game2D.gd`：
  - 敌人出生安全半径从 `24` 提高到 `54`，减少出生后第一步追击贴近障碍扩张区的概率。
- `tests/regression/regression_pseudo_34_safe_spawn_points.gd`：
  - 增强失败信息，若敌人贴障碍，会输出具体位置。
- 新增回归测试：
  - `tests/regression/regression_actor_spritesheet_texture_and_state.gd`

## 调试记录

- 完整回归第一次在安全出生点测试中失败。
- 失败位置显示敌人在开始追击后贴近障碍扩张区。
- 处理方式：提高敌人出生安全半径，让敌人生成时离障碍更远。
- 修复后安全出生点测试与完整回归通过。

## 验证结果

- 单项回归：`NEW_PROJECT_ACTOR_SPRITESHEET_TEXTURE_AND_STATE_OK`
- 相关回归：`NEW_PROJECT_PSEUDO_34_SAFE_SPAWN_POINTS_OK`
- 完整回归：`ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动：`HEADLESS_EXIT 0`
- Godot 测试残留进程检查：未列出残留 `Godot_v4.6.2-stable_win64` 进程

## 未触碰内容

- 未清除玩家存档。
- 未改动存档 schema。
- 未导入正式 IMAGE2 角色图片。
- 未恢复旧 3D 项目资源。
- 未恢复 POLYGON 资源。

## 当前限制

- 贴图加载已可用，但当前项目还没有正式 IMAGE2 生成素材。
- 动画帧推进仍需要外部调用 `advance_actor_animation()`，还没有按真实时间自动播放。
- 程序化多边形外观仍保留，正式素材接入前不会隐藏。

## 下一步建议

1. 用真实时间累计驱动 `advance_actor_animation()`，让 SpriteSheet 动画自动播放。
2. 当 `ActorSprite.texture` 可用且 manifest enabled 时，允许隐藏程序化身体。
3. 为玩家和敌人补 `death` 动画入口。
4. 等 IMAGE2 素材生成后，导入一套玩家 idle/run/attack 序列帧做实机验证。
