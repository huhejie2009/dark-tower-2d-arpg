# 2026-06-06 塔卫 IMAGE2 动作条与 Manifest 接入

## 本次目标

从 `enemy_tower_guardian_seed_v1.png` 开始，制作第一套可被 Godot 运行时加载的 IMAGE2 敌人 spritesheet，并通过现有 `visual_asset_manifest` 接入塔卫敌人。

## 已完成

- 生成塔卫第一版规范化动作条：
  - `res://assets/generated/actors/enemy_tower_guardian_sheet_v1.png`
  - 尺寸：`2560x128`
  - 单帧：`128x128`
  - 帧数：20
- 生成预览图：
  - `docs/concepts/world_art_direction/enemy_tower_guardian_sheet_v1_preview.png`
- 动画段：
  - `idle`: 0-3
  - `run`: 4-9
  - `attack`: 10-15
  - `death`: 16-19
- `FloorRules.get_enemy_type_data("tower_guardian")` 现在会带默认 IMAGE2 manifest。
- `Enemy2D.apply_enemy_data()` 在敌人数据包含 `visual_asset_manifest` 时会自动应用贴图 manifest。
- 塔卫生成后可以自动加载 `enemy_tower_guardian_sheet_v1.png`，隐藏程序化 `EnemyBody`。

## 新增回归

- `tests/regression/regression_tower_guardian_image2_manifest.gd`

覆盖内容：

- 塔卫敌人数据暴露 IMAGE2 manifest。
- manifest 启用、隐藏程序化身体、引用正确 spritesheet。
- manifest 包含 `idle/run/attack/death`。
- `Enemy2D.apply_enemy_data()` 自动加载塔卫 spritesheet。
- `ActorSprite` 有贴图，程序化身体隐藏，初始动画为 `idle`。

## 当前限制

这是一版“可加载/可播放/可验证”的动作条试验，不是最终高质量动作。

- 动作帧来自种子帧的局部变换和归一化，幅度较小。
- `run/attack/death` 目前更接近占位动作，用于验证接口和实机替换效果。
- 后续仍需要用 IMAGE2 以同一角色为基准生成真正的整条动画。

## 验证结果

- `NEW_PROJECT_TOWER_GUARDIAN_IMAGE2_MANIFEST_OK`
- `NEW_PROJECT_ENEMY_TYPE_STATS_OK`
- `NEW_PROJECT_GAME2D_FLOOR_TEMPLATE_SPAWN_OK`
- `NEW_PROJECT_ACTOR_SPRITESHEET_TEXTURE_AND_STATE_OK`
- `NEW_PROJECT_ACTOR_ANIMATION_AUTOPLAY_AND_VISIBILITY_OK`
- `ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动：`HEADLESS_EXIT 0`
- 未发现残留 Godot 测试进程。

## 未触碰内容

- 未清除玩家存档。
- 未回到旧 3D 项目。
- 未恢复 POLYGON 资源。
- 未直接替换所有敌人素材。

## 下一步建议

1. 在实机场景中重点试玩第 4 层或包含 `tower_guardian` 的楼层，观察尺寸、锚点、遮挡和动作速度。
2. 如果尺寸合适，继续给 `rot_melee` 做同样的规范化动作条。
3. 如果尺寸不合适，先调整 frame size 或缩放策略，再扩展到其他敌人。
