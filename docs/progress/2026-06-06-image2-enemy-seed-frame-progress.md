# 2026-06-06 IMAGE2 敌人与 Boss 种子帧补齐记录

## 本次目标

继续按 `远景宽体通天塔` 的美术基准补齐第一批敌人与 Boss 种子帧。

统一风格：

- 冷灰、低饱和。
- 粗粝混凝土、暗石、旧铁。
- 黑暗奇幻，但不华丽。
- 少光效，仅保留克制的黑蓝暗光。
- 不使用中式元素。
- 纯绿色背景，便于后续抠图。

## 本次新增素材

目录：

`res://assets/generated/actors/seed_frames/`

文件：

- `enemy_shadow_archer_seed_v1.png`
  - 类型：暗影射手。
  - 识别点：黑灰破斗篷、弓、微弱黑蓝眼光/弓弦。
  - 判断：远程怪轮廓明确，黑蓝弓弦略亮，但可作为种子帧。
- `enemy_tower_guardian_seed_v1.png`
  - 类型：塔卫。
  - 识别点：混凝土块甲、暗铁环、重盾、钝器。
  - 判断：和通天塔材质高度一致，可作为塔内人造守卫基准。
- `boss_tower_gatekeeper_seed_v1.png`
  - 类型：门卫 Boss。
  - 识别点：宽体重甲、塔门盾、胸口/面甲中心暗光条。
  - 判断：非常适合作为第一版小 Boss 视觉基准。

## 当前第一批种子帧清单

已具备：

- `player_warrior_seed_v1.png`
- `enemy_rot_melee_seed_v1.png`
- `enemy_shadow_archer_seed_v1.png`
- `enemy_tower_guardian_seed_v1.png`
- `boss_tower_gatekeeper_seed_v1.png`

## 使用边界

这些图片目前不直接替换实机角色动画。

原因：

- 当前图片仍是大尺寸种子图，不是统一帧尺寸的 spritesheet。
- 角度和比例需要归一化。
- 需要抠图、锚点统一、缩放测试。
- 需要生成同一角色的 `idle/run/attack/death` 动作条后，再通过 `visual_asset_manifest` 接入。

## 下一步建议

优先从 `enemy_rot_melee_seed_v1.png` 或 `enemy_tower_guardian_seed_v1.png` 开始做第一条规范化动作条，因为它们的轮廓最适合测试：

1. 抠图生成透明 PNG。
2. 建立 96x96 或 128x128 的底部中心锚点规范。
3. 生成 `idle/run/attack/death` 动作条。
4. 接入 `Enemy2D.gd` 现有 `visual_asset_manifest`。
5. 保留程序化身体作为 fallback。

推荐先做 `enemy_tower_guardian`：

- 材质贴合塔世界观。
- 动作慢，帧漂移风险较小。
- 体型重，游戏里更容易看出素材替换效果。
