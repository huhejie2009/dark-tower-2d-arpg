# 2026-06-07 多方向 IMAGE2 角色素材管线

本项目的角色动作素材分两阶段支持：

1. `runtime_flip_2dir`：当前可玩阶段使用。素材只有一套正向/斜向动作，运行时用左右翻转和脚步相位补足方向感。
2. `4dir` / `8dir`：正式多方向素材。每个方向都有独立帧段，运行时按方向偏移读取帧，不再翻转。

## 当前默认模式

现有玩家、敌人、Boss v3 素材仍使用：

```gdscript
"direction_mode": "runtime_flip_2dir"
```

这表示：

- `left` 方向通过 `ActorSprite.flip_h` 表示。
- `right` 方向使用原图。
- `up/down` 暂时使用同一套图，只通过运行时 bob、脚步相位和攻击位移补表现。

## 4 向正式素材

推荐第一批正式素材使用 4 向：

- `down`
- `left`
- `right`
- `up`

每个方向 20 帧，动作段固定：

- `idle`: 0-3
- `run`: 4-9
- `attack`: 10-15
- `death`: 16-19

横向总帧数为 `4 * 20 = 80` 帧。

推荐帧条排列：

```text
down idle/run/attack/death  | frames 0-19
left idle/run/attack/death  | frames 20-39
right idle/run/attack/death | frames 40-59
up idle/run/attack/death    | frames 60-79
```

Manifest 示例：

```gdscript
{
	"asset_pipeline": "image2",
	"pose_variation_version": "production_dark_armor_v3",
	"direction_mode": "4dir",
	"direction_order": ["down", "left", "right", "up"],
	"direction_frame_offsets": {
		"down": 0,
		"left": 20,
		"right": 40,
		"up": 60,
	},
	"enabled": true,
	"hide_procedural_body": true,
	"sprite_sheet_path": "res://assets/generated/actors/player_warrior_4dir_sheet_v1.png",
	"frame_size": Vector2i(160, 160),
	"animations": {
		"idle": {"from": 0, "to": 3, "fps": 6},
		"run": {"from": 4, "to": 9, "fps": 9},
		"attack": {"from": 10, "to": 15, "fps": 10},
		"death": {"from": 16, "to": 19, "fps": 6},
	},
}
```

运行时会用：

```text
resolved_frame_index = direction_frame_offsets[facing_bucket] + actor_animation_frame
```

因此动画段 `from/to` 仍只写单方向内部帧，不需要为每个方向重复写 `idle_down`、`idle_left`。

## 8 向正式素材

8 向可以沿用同一机制，只需要把 `direction_mode` 改为 `8dir`，并补齐方向偏移。

建议方向顺序：

```text
down, down_left, left, up_left, up, up_right, right, down_right
```

每方向 20 帧，总帧数为 160。

## IMAGE2 生成要求

生成多方向素材时，不要让 IMAGE2 输出角色跨格或跨行。提示词必须强调：

- flat solid `#00ff00` chroma-key background。
- no UI, no text, no labels, no floor, no shadow。
- exact sprite sheet, consistent cell size, generous padding。
- one character only。
- each direction separated into a clean row or clean horizontal block。
- top-down 3/4 ARPG camera, not side view。
- dark realistic armor/cloak style matching `production_dark_armor_v3`。

## 当前验证

新增测试：

- `tests/regression/regression_actor_directional_manifest_contract.gd`

它验证：

- `4dir` manifest 可以被玩家和敌人读取。
- `down/left/right/up` 会解析到不同的 `resolved_frame_index`。
- `4dir` 模式不会再使用运行时水平翻转。

聚焦验证结果：

- `NEW_PROJECT_ACTOR_DIRECTIONAL_MANIFEST_CONTRACT_OK`
- `DIRECTIONAL_IMAGE2_MANIFEST_FOCUSED_OK`
