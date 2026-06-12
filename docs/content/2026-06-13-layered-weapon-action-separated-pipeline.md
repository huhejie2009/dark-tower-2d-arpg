# 2026-06-13 动作分离与武器分层管线

## 结论

玩家角色正式管线切换为：

```text
animation_pipeline: action_separated
weapon_layer_mode: external_attach
```

这意味着 idle, run, attack, and death are generated separately。玩家身体动画只负责身体、披风、手臂和握持姿态；武器不再直接画死在身体帧里。

## 为什么废弃混合动画生成

一次生成 `idle + run + attack + death` 会降低质量：

- IMAGE2 容易把攻击姿势混进跑步。
- 死亡帧容易混入站立或攻击姿态。
- 每个动作的帧数和节奏难以控制。
- 角色锚点更容易漂移。

正式生产中，idle、run、attack、death 必须单独生成、单独 QA、单独切格。只有单个动作通过后，才允许合入角色总表。

## 为什么武器必须分层

body sprites must not include baked weapons。玩家以后会更换武器，如果武器直接生成在手上，会造成：

- 每换一种武器都要重做整套角色动画。
- 武器稀有度、外观、职业限制难以表现。
- 攻击特效和武器轨迹难以独立调整。

因此玩家身体帧只保留空手/握持姿势。剑、斧、弓、法杖等外观走独立 weapon sprite 或 weapon sheet。

## 角色身体动作标准

每个方向、每个动作单独生成：

```text
player_warrior_body_down_idle_v1.png
player_warrior_body_down_run_v1.png
player_warrior_body_down_attack_v1.png
player_warrior_body_down_death_v1.png
```

最低流畅帧数：

```text
idle_min_frames: 6
run_min_frames: 8
attack_min_frames: 10
death_min_frames: 8
target_fps_min: 8
target_fps_max: 12
```

验收要求：

- `idle`：呼吸和重心变化自然，不像冻结。
- `run`：必须有明确左右脚交替，不能只是身体平移。
- `attack`：必须包含预备、发力、命中姿势、收招。
- `death`：必须有可读倒地过程，不是透明消失。
- 所有 standing/running/attacking 帧底部锚线一致。

## 武器挂点轨道

角色身体动作必须提供 weapon_anchor_tracks：

```text
weapon_anchor_tracks:
  - weapon_socket_position
  - weapon_socket_rotation
  - weapon_draw_order
```

第一版可以先用文档/JSON 记录每帧挂点，后续再做 Godot Resource：

```json
{
  "animation": "attack",
  "direction": "down",
  "frames": [
    {"frame": 0, "position": [12, -34], "rotation_degrees": -18, "draw_order": "front"},
    {"frame": 1, "position": [14, -32], "rotation_degrees": -8, "draw_order": "front"}
  ]
}
```

## 武器素材标准

武器单独生成或手工绘制：

```text
weapon_short_sword_pixel_v1.png
weapon_axe_pixel_v1.png
weapon_staff_pixel_v1.png
weapon_bow_pixel_v1.png
```

要求：

- 透明背景。
- 单独图层，不带角色手臂。
- 和角色同一像素密度、同一低饱和暗黑色调。
- 不包含打击特效。

## 运行时接口

当前玩家节点预留：

```text
ActorVisualRoot
  ActorSprite
  WeaponSprite
```

`ActorSprite` 负责身体动画。`WeaponSprite` 只作为后续装备外观接口，当前不接入正式运行表现。

## 当前禁止事项

- 不再把带武器的人物帧当作正式玩家身体素材。
- 不再一次生成完整 `idle/run/attack/death` 混合表作为正式素材。
- 不把挥砍光轨、命中特效、投射物画进身体或武器帧。
- 不在未通过锚点 QA 前切换运行时 manifest。
