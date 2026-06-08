# 2026-06-05 IMAGE2 角色素材目录约定

## 目录

后续 IMAGE2 生成的玩家、敌人和 Boss 2D 动画素材统一放在：

`res://assets/generated/actors/`

当前目录只保留 `.gitkeep`，暂不导入正式图片。

## 推荐命名

- 玩家：
  - `player_warrior_sheet.png`
  - `player_ranger_sheet.png`
  - `player_mage_sheet.png`
  - `player_necromancer_sheet.png`
- 普通敌人：
  - `enemy_rot_melee_sheet.png`
  - `enemy_shadow_archer_sheet.png`
  - `enemy_tower_guardian_sheet.png`
- Boss：
  - `boss_tower_gatekeeper_sheet.png`

## Manifest 结构

角色脚本当前支持以下 manifest 结构：

```gdscript
{
	"asset_pipeline": "image2",
	"enabled": true,
	"sprite_sheet_path": "res://assets/generated/actors/player_warrior_sheet.png",
	"frame_size": Vector2i(64, 64),
	"animations": {
		"idle": {"from": 0, "to": 3, "fps": 8},
		"run": {"from": 4, "to": 9, "fps": 10},
		"attack": {"from": 10, "to": 15, "fps": 12}
	}
}
```

## 当前接入点

- 玩家：`Player2D.gd`
  - `ActorVisualRoot`
  - `ActorSprite`
  - `apply_visual_asset_manifest()`
  - `set_actor_animation()`
  - `advance_actor_animation()`
- 敌人：`Enemy2D.gd`
  - `ActorVisualRoot`
  - `ActorSprite`
  - `apply_visual_asset_manifest()`
  - `set_actor_animation()`
  - `advance_actor_animation()`

## 注意

- 当前第一版只维护动画名和 SpriteSheet 帧区域，不自动加载图片资源。
- 后续导入图片后，可以在 manifest 应用阶段加载 `sprite_sheet_path`，设置到 `ActorSprite.texture`。
- 程序化多边形身体仍保留，直到正式素材质量足够替换。
