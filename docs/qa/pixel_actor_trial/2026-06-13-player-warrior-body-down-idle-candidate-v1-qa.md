# 2026-06-13 玩家战士身体下方向 Idle 候选 V1 QA

## 文件

绿幕源图：

```text
docs/concepts/pixel_actor_trial/player_warrior_body_down_idle_candidate_v1_green.png
```

透明候选：

```text
assets/generated/actors/candidates/player_warrior_body_down_idle_candidate_v1.png
```

## 结论

该图作为 `player_warrior_body_down_idle_v1` 的候选保留，可进入切格和锚点评估；暂不接入实机 manifest。

## 通过项

- 8 帧单动作结构成立，没有混入 run、attack、death。
- 角色身体没有烘焙武器；双手没有剑、斧、弓、法杖或盾牌。
- 透明候选已经生成，可用于后续切格检查。
- 盔甲、披风、低饱和暗色方向符合当前世界观。
- 帧间姿态相对稳定，没有明显横向大漂移。

## 风险项

- 呼吸和重心变化偏小，实机播放时可能显得不够“活”。
- 像素颗粒仍偏软，部分细节更像缩小厚涂。
- 披风和腿部边缘需要切格后检查透明边缘是否干净。
- 需要后续生成带锚线的预览图，检查脚底基线是否稳定。
- 2026-06-13 切格分析显示脚底基线稳定，但角色在 cell 内的横向中心漂移明显，后续必须做归一化重排。

## 下一步

1. 使用归一化脚本把 8 帧重新居中到底部锚点。
2. 输出归一化后的 preview sheet。
3. 再次检查脚底基线、中心漂移和 idle 呼吸幅度。
4. 如果归一化后表现稳定，再尝试制作 `player_warrior_body_down_run_v1`。

## 2026-06-13 切格与锚线指标

指标文件：

```text
docs/qa/pixel_actor_trial/player_warrior_body_down_idle_candidate_v1_metrics.json
```

锚线预览：

```text
docs/qa/pixel_actor_trial/player_warrior_body_down_idle_candidate_v1_baseline_preview.png
```

关键结果：

```text
frame_count: 8
cell_width: 271
global_foot_y: 498
max_foot_baseline_drift_px: 2
runtime_connected: false
approved_for_manifest_switch: false
```

判断：

- 脚底基线通过初筛。
- 原始 cell 内横向中心不稳定，需要归一化后才允许进入运行时测试。

## 资产状态

```text
status: candidate_cutting_ready
runtime_connected: false
approved_for_manifest_switch: false
candidate_direction: down
candidate_action: idle
candidate_frame_count: 8
body_sprites_exclude_weapon: true
```
