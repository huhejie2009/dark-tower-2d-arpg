# 2026-06-13 玩家战士 4 向像素候选图 QA

## 文件

```text
docs/concepts/pixel_actor_trial/player_warrior_4dir_pixel_sheet_candidate_v1.png
```

## 结论

该图作为风格候选保留，不作为实机运行素材接入。

## 通过项

- 角色整体比例比 Q 版像素更接近当前暗黑 ARPG 方向。
- 黑铁盔甲、蓝灰披风、短剑和低饱和色调符合世界观。
- 4 行朝向结构基本可读，能作为下一轮生成参考。
- 攻击和死亡动作比之前“静止图左右晃动”的方案更有动作意图。

## 未通过项

- 每行不足 20 帧，不满足正式 `4dir * 20 = 80` 帧规格。
- 背景是绿幕候选，不是透明成品。
- 部分帧脚底锚点有横向和纵向漂移。
- 像素颗粒感仍偏弱，更像缩小后的厚涂角色。
- `run` 动作仍需更明确的左右脚交替。
- `attack` 需要更稳定的预备、挥出、收招节奏。

## 下一轮 IMAGE2 约束

- 明确要求 `exactly 20 equally spaced frames in each row`。
- 明确要求 `strict grid, no merged poses, no missing cells`。
- 明确要求 `visible pixel clusters, no painterly brush texture`。
- 要求角色脚底在每一格同一水平线上。
- 先只生成单方向 20 帧小条验证，再扩展到 4 向整表。

## 资产状态

```text
status: candidate_reference_only
runtime_connected: false
approved_for_cutting: false
approved_for_manifest_switch: false
```
