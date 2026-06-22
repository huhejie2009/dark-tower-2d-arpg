# 游侠寒冰 CoC 视觉套装进度

日期：2026-06-11

## 已完成

- 新增程序化游侠 20 帧 SpriteSheet。
- 游侠进入战斗时使用 `player_ranger_sheet_v1.png` manifest。
- 战士继续使用现有 `player_warrior_sheet_v3.png`。
- 寒冰射击使用冰箭轨迹。
- 冰矛使用更细、更亮的冰矛轨迹。
- CoC 触发时生成蓝白触发闪光。

## 验证

- `regression_ranger_visual_kit_assets.gd`
- `regression_class_basic_skill_presentation.gd`
- `regression_ranger_ice_vfx_contract.gd`
- `regression_default_image2_player_art_contract.gd`
- `regression_ranger_coc_player_cast.gd`
- `regression_scene_boot.gd`

## 已知限制

- 游侠 SpriteSheet 是程序化生成资产，不是最终商用品质。
- 仍使用 `runtime_flip_2dir`，尚未制作四方向角色。
- 弓包含在角色帧内，尚未支持装备换装。
- 法师和侍僧仍使用程序化占位外观。
