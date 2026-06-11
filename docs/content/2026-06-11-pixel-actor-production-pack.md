# 2026-06-11 像素角色正式素材生产包 V1

## 使用范围

本生产包用于把“场景厚涂/半写实 + 角色暗黑高分辨率像素”的试点推进到可生产素材。第一批只做三个单位：

- 玩家战士：`player_warrior`
- 近战小怪：`rot_melee`
- 远程小怪：`shadow_archer`

Boss、主城 NPC、装备换装外观暂不进入本批次。

## 统一画风要求

- 暗黑高分辨率像素，不做 Q 版，不做卡通可爱比例。
- 低饱和、冷灰、黑铁、暗蓝、锈红作为主色系。
- 角色轮廓必须能在深色石材地面上读出来。
- 每个角色脚底锚点保持底部中心，不允许帧间漂移。
- 不把打击火花、挥砍光轨、投射物、地面警示画进角色帧条。
- 角色帧条背景必须是纯透明；如果 IMAGE2 暂时不能直接透明，则先用纯 `#00ff00` 背景并做本地抠图。

## 帧条规格

### 过渡期

当前项目仍可使用：

```gdscript
"direction_mode": "runtime_flip_2dir"
```

这表示只用一套朝向帧条，运行时左右翻转。它只适合继续试玩，不作为正式交付目标。

### 正式目标

正式第一批素材使用 4 向：

```gdscript
"direction_mode": "4dir"
"direction_order": ["down", "left", "right", "up"]
"direction_frame_offsets": {
	"down": 0,
	"left": 20,
	"right": 40,
	"up": 60,
}
```

每个方向 20 帧：

| 动作 | 帧段 | 说明 |
| --- | --- | --- |
| `idle` | 0-3 | 呼吸、重心轻微变化 |
| `run` | 4-9 | 明确换脚，不允许只是整体平移 |
| `attack` | 10-15 | 武器/手臂必须有清楚预备、挥出、收招 |
| `death` | 16-19 | 倒地或崩散，不要只是透明消失 |

总帧数：`4 * 20 = 80`。

## 目标文件名

```text
assets/generated/actors/player_warrior_4dir_pixel_sheet_v1.png
assets/generated/actors/enemy_rot_melee_4dir_pixel_sheet_v1.png
assets/generated/actors/enemy_shadow_archer_4dir_pixel_sheet_v1.png
```

## IMAGE2 通用提示词骨架

```text
Create one production sprite sheet for a dark high-resolution pixel-art actor in a 2D top-down 3/4 ARPG.

Character: <角色描述>
Style: dark fantasy, high-resolution pixel art, crisp square pixel clusters, desaturated, gritty, readable at game scale, not cute, not chibi, not cartoon.
Camera: top-down 3/4 ARPG sprite camera.
Sheet layout: one horizontal strip or clean row blocks, exactly 80 frames total, 4 directions in this order: down, left, right, up.
Per direction: 20 frames. idle frames 0-3, run frames 4-9, attack frames 10-15, death frames 16-19.
Animation requirements: run must show alternating feet; attack must show clear windup, strike, and recovery; death must show visible body collapse.
Consistency: same character, same silhouette, same palette, same armor proportions, same weapon size, same foot anchor across every frame.
Background: perfectly flat solid #00ff00 chroma-key background, no floor, no shadow, no UI, no text, no labels, no watermark.
Do not include hit sparks, slash trails, projectiles, impact VFX, ground decals, scenery, props, poster composition, or multiple characters.
```

## 玩家战士提示词

```text
Character: player warrior wearing dark steel armor, a torn blue-gray cloak, compact shoulder armor, leather belts, one short sword in the right hand, tired heroic posture, cold blue rim accents, grounded but not heroic-poster exaggerated.
Important silhouette: readable cloak edge, sword angled forward, helmet or shadowed face, medium build.
Avoid: golden paladin armor, glowing angel wings, oversized sword, bright saturated blue, cute proportions.
```

## 腐朽近战怪提示词

```text
Character: rot melee enemy wearing rusted black armor plates, corrupted red-brown cloth strips, clawed hands or short jagged blade, hunched aggressive posture, exposed dark gaps between armor plates, diseased but not zombie-comedy.
Important silhouette: forward shoulders, uneven arms, threatening hand or blade, smaller than player.
Avoid: bright blood splashes, cartoon zombie face, exaggerated giant claws, clean heroic armor.
```

## 暗影弓手提示词

```text
Character: shadow archer enemy wearing a dark hooded leather cloak, compact bow, slim build, cold blue-gray accent cloth, hidden face, cautious ranged stance.
Important silhouette: bow must read clearly, hood profile visible, attack frames must show draw and release.
Avoid: giant fantasy longbow, glowing neon arrows, cute rogue outfit, bright purple robe.
```

## 导入验收清单

- 每个文件可以被 Godot 正常加载为 PNG。
- 角色背景已经透明，或绿幕可以无明显边缘地抠干净。
- 每帧角色脚底锚点稳定，没有横向/纵向漂移。
- `run` 帧能看到左右脚交替。
- `attack` 帧能看到武器或手臂动作，不只是抖动。
- `death` 帧能看到明确死亡状态。
- 在 1280x720 战斗场景截图中，玩家、近战怪、远程怪的轮廓都能在石材地面上读清楚。
- 替换后以下回归通过：
  - `regression_pixel_actor_art_trial_contract.gd`
  - `regression_actor_directional_manifest_contract.gd`
  - `regression_default_image2_player_art_contract.gd`
  - `regression_rot_melee_image2_manifest.gd`
  - `regression_shadow_archer_image2_manifest.gd`

## 当前预览图

像素角色三人组风格预览：

```text
docs/concepts/pixel_actor_trial/pixel_actor_lineup_preview_v1.png
```

该图只用于方向判断，不作为最终游戏资源。
