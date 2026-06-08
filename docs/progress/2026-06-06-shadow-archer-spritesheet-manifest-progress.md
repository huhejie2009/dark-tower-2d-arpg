# 2026-06-06 暗影射手 IMAGE2 动作条与默认接入进度

## 本次目标

在 `tower_guardian` 和 `rot_melee` 已接入第一版 IMAGE2 动作条后，继续把远程怪 `shadow_archer` 纳入同一套可替换素材管线，让第 3 层开始出现的远程压力怪不再依赖抽象程序图形。

## 已完成

- 新增暗影射手动作条：
  - `res://assets/generated/actors/enemy_shadow_archer_sheet_v1.png`
  - 规格：横向 20 帧，单帧 `128 x 128`，整图 `2560 x 128`
  - 动画分段：
    - `idle`: 0-3，6 fps
    - `run`: 4-9，8 fps
    - `attack`: 10-15，10 fps
    - `death`: 16-19，6 fps
- 新增预览图：
  - `res://docs/concepts/world_art_direction/enemy_shadow_archer_sheet_v1_preview.png`
- 处理了种子帧中的绿色背景，将动作条导出为透明底，避免游戏中出现色块。
- 在 `FloorRules.gd` 中新增 `SHADOW_ARCHER_IMAGE2_MANIFEST`。
- `get_enemy_type_data("shadow_archer")` 现在会默认返回 `visual_asset_manifest`。
- 新增回归测试：
  - `res://tests/regression/regression_shadow_archer_image2_manifest.gd`

## 当前限制

- 这版动作仍是基于 IMAGE2 种子帧的规范化占位动画，不是最终逐帧动画。
- 攻击段已经有拉弓、放箭和残影提示，但真实射击动作还需要后续用 IMAGE2 生成更高质量版本。
- 远程怪在实机中需要重点观察：尺寸是否偏小、暗色轮廓是否足够可读、攻击前摇是否清楚。

## 验证结果

- `NEW_PROJECT_SHADOW_ARCHER_IMAGE2_MANIFEST_OK`
- `NEW_PROJECT_ROT_MELEE_IMAGE2_MANIFEST_OK`
- `NEW_PROJECT_TOWER_GUARDIAN_IMAGE2_MANIFEST_OK`
- `NEW_PROJECT_ENEMY_TYPE_STATS_OK`
- `NEW_PROJECT_GAME2D_FLOOR_TEMPLATE_SPAWN_OK`
- `NEW_PROJECT_ACTOR_SPRITESHEET_TEXTURE_AND_STATE_OK`
- `NEW_PROJECT_ACTOR_ANIMATION_AUTOPLAY_AND_VISIBILITY_OK`
- `ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动退出码：`0`

## 进程状态

- 验证后没有残留本次 headless 测试进程。
- 检测到一个普通 `Godot.exe` 编辑器进程，未关闭。

## 未触碰内容

- 没有清除玩家存档。
- 没有回到旧 3D 项目。
- 没有恢复或接入 POLYGON 资源。

## 推荐下一步

1. 真实试玩第 3 到第 5 层，检查 `rot_melee`、`shadow_archer`、`tower_guardian` 三类敌人在同一画面中的尺寸和可读性。
2. 如果普通敌人表现稳定，继续制作 `boss_tower_gatekeeper` 的第一版动作条和默认素材清单。
3. 后续再把当前占位动作条替换为更完整的 IMAGE2 逐帧动画资产。
