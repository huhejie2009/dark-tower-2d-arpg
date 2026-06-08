# 2026-06-07 玩家与 Boss 暗黑写实 v3 动作素材接入进度

继续沿用 `production_dark_armor_v3` 美术方向，把玩家和 Boss 从旧单帧/程序化占位推进到与普通敌人一致的暗黑写实动作条。

## 本轮目标

- 玩家不再使用旧的单帧站立图。
- Boss `tower_gatekeeper` 不再只使用程序化多边形身体。
- 玩家、普通敌人、Boss 在同一房间内保持统一的黑甲、斗篷、冷色钢铁风格。
- 保持现有 IMAGE2 SpriteSheet manifest 接口，不改存档和核心战斗规则。

## 新增素材

玩家：

- `res://assets/generated/actors/player_warrior_sheet_v3.png`
- `res://assets/generated/actors/image2_sources/player_warrior_sheet_v3_image2_source.png`
- `res://docs/concepts/world_art_direction/player_warrior_sheet_v3_preview.png`

Boss：

- `res://assets/generated/actors/boss_tower_gatekeeper_sheet_v3.png`
- `res://assets/generated/actors/image2_sources/boss_tower_gatekeeper_sheet_v3_image2_source.png`
- `res://docs/concepts/world_art_direction/boss_tower_gatekeeper_sheet_v3_preview.png`

## 接入修改

- `Game2D.gd`
  - `DEFAULT_PLAYER_IMAGE2_SPRITE_PATH` 改为 `player_warrior_sheet_v3.png`。
  - 默认玩家 manifest 增加 `pose_variation_version = production_dark_armor_v3`。
  - 玩家默认动画段改为：
    - `idle 0-3`
    - `run 4-9`
    - `attack 10-15`
    - `death 16-19`

- `FloorRules.gd`
  - 新增 `TOWER_GATEKEEPER_IMAGE2_MANIFEST`。
  - Boss 使用 `boss_tower_gatekeeper_sheet_v3.png`，帧尺寸为 `192x192`。
  - `get_enemy_type_data("tower_gatekeeper")` 现在会返回 Boss 默认 IMAGE2 manifest。

- `Player2D.gd`
  - 修复重复设置同一动画会重置帧的问题。
  - 应用 manifest 时强制初始化 `idle` 第一帧，避免 `region_rect` 为空。

- `Enemy2D.gd`
  - 同步让敌人在应用 manifest 时强制初始化 `idle` 第一帧，避免同类隐患。

## 素材处理说明

- 玩家源图可直接按两行动作条转为 20 帧横向透明 PNG。
- Boss 第一张重试图布局更清楚，但角色体块过宽，严格网格会切开身体；最终改用第二张 Boss 源图做主体识别，并手动重排为标准动画段。
- Boss 当前已可用，但仍建议后续做 v4：专门生成更规整的 `idle/run/attack/death` 两行帧条，减少重排成本。

## 新增/更新测试

- 新增 `tests/regression/regression_player_boss_production_spritesheets.gd`
  - 检查玩家和 Boss PNG 能加载。
  - 检查横向 20 帧尺寸。
  - 检查关键帧可读宽高。
  - 检查无绿幕残留。
  - 检查移动、攻击、死亡段有动作变化。

- 更新 `tests/regression/regression_default_image2_player_art_contract.gd`
  - 玩家默认素材必须指向 `player_warrior_sheet_v3.png`。
  - 玩家必须暴露 `production_dark_armor_v3` manifest。
  - 玩家必须有 `idle/run/attack/death` 动画段。

- 更新 `tests/regression/regression_game2d_boss_spawn.gd`
  - 第 5 层 Boss 必须加载 `boss_tower_gatekeeper_sheet_v3.png`。
  - Boss 程序化身体必须隐藏。
  - Boss manifest 必须使用 `production_dark_armor_v3`。

## 聚焦验证

已通过：

- `NEW_PROJECT_PLAYER_BOSS_PRODUCTION_SPRITESHEETS_OK`
- `NEW_PROJECT_DEFAULT_IMAGE2_PLAYER_ART_CONTRACT_OK`
- `NEW_PROJECT_GAME2D_BOSS_SPAWN_OK`
- `NEW_PROJECT_ACTOR_SPRITESHEET_ANIMATION_CONTRACT_OK`
- `NEW_PROJECT_ACTOR_SPRITESHEET_TEXTURE_AND_STATE_OK`
- `NEW_PROJECT_PLAYER_DEATH_PRESENTATION_USES_MANIFEST_DURATION_OK`
- `PLAYER_BOSS_PRODUCTION_V3_FOCUSED_OK`

## 后续建议

1. 进 Godot 实机看第 1 层和第 5 层：重点观察玩家尺寸、Boss 尺寸、血条位置和攻击读帧。
2. 生成 Boss v4 规整帧条，减少目前因源图布局造成的重排痕迹。
3. 继续补玩家职业差异化：战士、游侠、法师可以先共享底层动画接口，再替换不同职业素材。
