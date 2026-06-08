# 2026-06-06 敌人暗黑写实 v3 动作素材替换进度

本轮根据新的目标参考图调整敌人素材方向。之前的 `limb_keyed_v2` 已能证明动画状态和帧切换有效，但整体仍是工程占位符，和目标图中的暗黑写实塔内战斗画面不在同一美术层级。

## 本轮目标

- 敌人外观转向冷峻水泥巨构塔内的暗黑写实风格。
- 普通近战、暗影射手、塔卫都要具备清晰职业轮廓。
- 移动、攻击、死亡不再只是静态图片抖动，而是能看出腿部步态、武器动作和倒地过程。
- 继续保留现有 IMAGE2 SpriteSheet 接口，不改战斗逻辑和存档。

## 新增素材

生成并接入了三套新的 20 帧横向动作条：

- `res://assets/generated/actors/enemy_rot_melee_sheet_v3.png`
- `res://assets/generated/actors/enemy_shadow_archer_sheet_v3.png`
- `res://assets/generated/actors/enemy_tower_guardian_sheet_v3.png`

同时保留 IMAGE2 原始绿幕源图，方便后续重新切图或继续迭代：

- `res://assets/generated/actors/image2_sources/enemy_rot_melee_sheet_v3_image2_source.png`
- `res://assets/generated/actors/image2_sources/enemy_shadow_archer_sheet_v3_image2_source.png`
- `res://assets/generated/actors/image2_sources/enemy_tower_guardian_sheet_v3_image2_source.png`

预览图：

- `res://docs/concepts/world_art_direction/enemy_rot_melee_sheet_v3_preview.png`
- `res://docs/concepts/world_art_direction/enemy_shadow_archer_sheet_v3_preview.png`
- `res://docs/concepts/world_art_direction/enemy_tower_guardian_sheet_v3_preview.png`

## 接入修改

- `FloorRules.gd`
  - 三类敌人的 `visual_asset_manifest.sprite_sheet_path` 改为 v3 素材。
  - `pose_variation_version` 从 `limb_keyed_v2` 升级为 `production_dark_armor_v3`。

## 素材处理

- IMAGE2 输出是两行绿幕源图，不是 Godot 直接可用的横向动作条。
- 本轮使用本地处理将源图转为透明 PNG，并统一到当前运行时约定：
  - 20 帧横向排列。
  - 每帧 `128x128`。
  - 动画段仍为 `idle 0-3`、`run 4-9`、`attack 10-15`、`death 16-19`。
- 对近战怪跑步段补了少量重心位移，让移动更像真实步态。
- 塔卫源图只识别到 19 个独立主体，最后一帧死亡动作临时用死亡末帧补齐；后续建议单独生成塔卫 v4 时补完整死亡帧。

## 测试更新

已更新以下测试以锁定 v3 生产风格资产：

- `tests/regression/regression_enemy_spritesheet_pose_variation.gd`
- `tests/regression/regression_image2_enemy_asset_visual_quality.gd`
- `tests/regression/regression_rot_melee_image2_manifest.gd`
- `tests/regression/regression_shadow_archer_image2_manifest.gd`
- `tests/regression/regression_tower_guardian_image2_manifest.gd`

聚焦验证结果：

- `NEW_PROJECT_IMAGE2_ENEMY_ASSET_VISUAL_QUALITY_OK`
- `NEW_PROJECT_ENEMY_SPRITESHEET_POSE_VARIATION_OK`
- `NEW_PROJECT_ROT_MELEE_IMAGE2_MANIFEST_OK`
- `NEW_PROJECT_SHADOW_ARCHER_IMAGE2_MANIFEST_OK`
- `NEW_PROJECT_TOWER_GUARDIAN_IMAGE2_MANIFEST_OK`
- `NEW_PROJECT_GAME2D_IMAGE2_ENEMY_REPLACEMENT_OK`
- `ENEMY_PRODUCTION_DARK_ARMOR_V3_FOCUSED_OK`

## 后续建议

1. 用同一风格重新生成玩家动作条，避免玩家仍像旧素材。
2. 对塔卫单独做 v4，重点补完整死亡帧和更重的砸击帧。
3. 做一轮实机截图检查：人物尺寸、地面比例、血条和名字是否遮挡角色。
4. 后续再为 Boss `tower_gatekeeper` 制作同风格动作条。
