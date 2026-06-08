# 2026-06-05 IMAGE2 SpriteSheet 动画接口进度

## 本轮目标

继续推进 IMAGE2 角色素材接入准备工作，让玩家和敌人的 `ActorSprite` 不只是预留节点，而是具备第一版 SpriteSheet manifest 解析、动画切换和帧索引推进能力。

## 已完成

- `Player2D.gd`：
  - 保存 `visual_asset_manifest`。
  - 新增当前动画状态：
    - `actor_animation_name`
    - `actor_animation_frame`
    - `actor_animation_elapsed`
  - `apply_visual_asset_manifest()` 会读取 manifest，并在有 `idle` 动画时自动切到 `idle`。
  - 新增 `set_actor_animation()`，根据 manifest 中的 `from` 帧设置起始帧。
  - 新增 `advance_actor_animation()`，在当前动画 `from/to` 范围内推进并循环。
  - 新增 `get_actor_animation_state()`，用于读取当前动画名、帧索引、帧尺寸和素材路径。
  - `ActorSprite.region_rect` 会根据当前帧和 `frame_size` 更新。
- `Enemy2D.gd`：
  - 实现与玩家一致的 SpriteSheet manifest/动画状态接口。
- 新增素材目录：
  - `assets/generated/actors/.gitkeep`
- 新增素材约定文档：
  - `docs/content/2026-06-05-image2-actor-asset-convention.md`
- 新增回归测试：
  - `tests/regression/regression_actor_spritesheet_animation_contract.gd`

## 当前 manifest 格式

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

## 验证结果

- 单项回归：`NEW_PROJECT_ACTOR_SPRITESHEET_ANIMATION_CONTRACT_OK`
- 完整回归：`ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动：`HEADLESS_EXIT 0`
- Godot 测试残留进程检查：未列出残留 `Godot_v4.6.2-stable_win64` 进程

## 未触碰内容

- 未清除玩家存档。
- 未改动存档 schema。
- 未生成或导入正式 IMAGE2 图片。
- 未恢复旧 3D 项目资源。
- 未恢复 POLYGON 资源。

## 当前限制

- 当前接口只维护 SpriteSheet 帧区域和动画状态，还没有自动加载 `sprite_sheet_path` 对应贴图。
- 当前帧推进由外部调用 `advance_actor_animation()`，还没有接入真实时间累计或移动/攻击状态自动切换。
- 程序化多边形外观仍保留，正式素材接入前不会隐藏。

## 下一步建议

1. 实现 `sprite_sheet_path` 到 `ActorSprite.texture` 的加载逻辑。
2. 将玩家移动状态接到 `idle/run` 动画切换。
3. 将普通攻击接到 `attack` 动画切换。
4. 为敌人增加 `idle/run/attack/death` 的状态动画入口。
