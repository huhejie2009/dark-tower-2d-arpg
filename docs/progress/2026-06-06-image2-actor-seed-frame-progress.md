# 2026-06-06 IMAGE2 角色/怪物种子帧进度

## 本次目标

以 `2026-06-05-web-image2-far-wide-fantasy-tower-dark-core-large-preview.png` 作为美术基准，开始填充游戏内角色与怪物素材。

美术基准：

- 冷灰、低饱和。
- 粗粝混凝土、暗石、旧铁。
- 少光效，只保留克制的黑蓝暗光。
- 黑暗奇幻与远古人造工程感。
- 不使用中式建筑/服饰元素。

## 已生成并入库

目录：

`res://assets/generated/actors/seed_frames/`

文件：

- `player_warrior_seed_v1.png`
  - 角色：玩家战士。
  - 用途：玩家战士风格种子帧。
  - 判断：风格、装备、冷灰色调较合适，但更接近立绘级别，后续需要重新归一化为游戏内小 sprite。
- `enemy_rot_melee_seed_v1.png`
  - 角色：腐化近战怪。
  - 用途：基础近战怪风格种子帧。
  - 判断：混凝土/铁锈/黑蓝裂隙方向较合适，可作为后续 idle/run/attack/death 动画条参考。

## 未完成

本轮尝试中，以下素材还没有稳定拿到可入库版本：

- `shadow_archer` 暗影射手。
- `tower_guardian` 塔卫。
- `tower_gatekeeper` 门卫 Boss。

原因：

- 内置 IMAGE2 在连续生成时出现服务端错误/限流。
- 网页端批量生成提示进入图片编辑队列后不稳定，未形成可直接保存的结果。

## 接入原则

当前两张图不直接替换运行时角色贴图，先作为“种子帧/风格参考”保存。

后续正式接入应走：

1. 从种子帧派生标准化 sprite sheet。
2. 使用纯色背景或透明底，统一底部中心锚点。
3. 第一版建议每个角色使用：
   - `idle`: 4 帧
   - `run`: 6 帧
   - `attack`: 6 帧
   - `death`: 4 帧
4. 通过现有 `visual_asset_manifest` 接入：

```gdscript
{
	"asset_pipeline": "image2",
	"enabled": true,
	"hide_procedural_body": true,
	"sprite_sheet_path": "res://assets/generated/actors/player_warrior_sheet.png",
	"frame_size": Vector2i(96, 96),
	"animations": {
		"idle": {"from": 0, "to": 3, "fps": 8},
		"run": {"from": 4, "to": 9, "fps": 10},
		"attack": {"from": 10, "to": 15, "fps": 12},
		"death": {"from": 16, "to": 19, "fps": 8}
	}
}
```

## 下一步建议

1. 单张生成 `shadow_archer_seed_v1.png`。
2. 单张生成 `tower_guardian_seed_v1.png`。
3. 单张生成 `tower_gatekeeper_seed_v1.png`。
4. 从 `enemy_rot_melee_seed_v1.png` 开始做第一套规范化动作条试验。
5. 对接 `Player2D.gd` / `Enemy2D.gd` 现有 manifest，不破坏程序化占位体作为 fallback。
