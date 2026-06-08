# 2026-06-06 腐化近战怪 IMAGE2 动作条与默认接入进度

## 本次目标

在塔卫 `tower_guardian` 已完成第一版 IMAGE2 动作条接入后，继续把最基础、出现频率最高的普通怪 `rot_melee` 从抽象程序图形推进到可替换、可迭代的 2D 素材管线中。

## 已完成

- 新增腐化近战怪动作条：
  - `res://assets/generated/actors/enemy_rot_melee_sheet_v1.png`
  - 规格：横向 20 帧，单帧 `128 x 128`，整图 `2560 x 128`
  - 动画分段：
    - `idle`: 0-3，7 fps
    - `run`: 4-9，9 fps
    - `attack`: 10-15，11 fps
    - `death`: 16-19，7 fps
- 新增预览图：
  - `res://docs/concepts/world_art_direction/enemy_rot_melee_sheet_v1_preview.png`
- 在 `FloorRules.gd` 中新增 `ROT_MELEE_IMAGE2_MANIFEST`。
- `get_enemy_type_data("rot_melee")` 现在会默认返回 `visual_asset_manifest`。
- 复用现有 `Enemy2D.apply_enemy_data()` 的素材清单自动应用逻辑：
  - 加载成功时显示动作条素材。
  - 程序化身体作为加载失败时的兜底，不删除。
- 新增回归测试：
  - `res://tests/regression/regression_rot_melee_image2_manifest.gd`

## 当前限制

- 这版动作条是基于 IMAGE2 种子帧做的规范化占位动作，不是最终高质量逐帧动画。
- 动作已经分出待机、移动、攻击、死亡四段，但攻击张力和死亡帧表现还需要后续用 IMAGE2 重新生成更完整的动作组。
- 尺寸、锚点、碰撞和场景可读性还需要在真实试玩中继续校准。

## 验证结果

- `NEW_PROJECT_ROT_MELEE_IMAGE2_MANIFEST_OK`
- `NEW_PROJECT_ENEMY_TYPE_STATS_OK`
- `NEW_PROJECT_GAME2D_FLOOR_TEMPLATE_SPAWN_OK`
- `NEW_PROJECT_ACTOR_SPRITESHEET_TEXTURE_AND_STATE_OK`
- `NEW_PROJECT_ACTOR_ANIMATION_AUTOPLAY_AND_VISIBILITY_OK`
- `ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动退出码：`0`
- 验证后没有残留 Godot 测试进程。

## 未触碰内容

- 没有清除玩家存档。
- 没有回到旧 3D 项目。
- 没有恢复或接入 POLYGON 资源。

## 推荐下一步

1. 进入真实试玩检查前几层 `rot_melee` 的尺寸、朝向、脚底锚点和攻击可读性。
2. 如果基础怪表现可接受，继续制作 `shadow_archer` 动作条。
3. 如果远程怪接入顺利，再制作 `boss_tower_gatekeeper` 的第一版素材清单。
4. 后续统一把这些动作条替换为更完整的 IMAGE2 逐帧动画资产。
