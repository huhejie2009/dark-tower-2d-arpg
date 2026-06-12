# 2026-06-13 玩家战士 Idle 候选切格与锚线 QA 进度

## 本轮目标

对 `player_warrior_body_down_idle_candidate_v1.png` 做切格和脚底锚线检查，判断它能否进入下一阶段。

## 已完成

- 新增 QA 分析脚本：
  - `tools/qa_analyze_player_warrior_body_idle_candidate.gd`
- 生成指标文件：
  - `docs/qa/pixel_actor_trial/player_warrior_body_down_idle_candidate_v1_metrics.json`
- 生成锚线预览图：
  - `docs/qa/pixel_actor_trial/player_warrior_body_down_idle_candidate_v1_baseline_preview.png`
- 更新 QA 文档：
  - `docs/qa/pixel_actor_trial/2026-06-13-player-warrior-body-down-idle-candidate-v1-qa.md`
- 新增回归：
  - `tests/regression/regression_player_warrior_body_idle_anchor_metrics.gd`

## 指标结论

```text
frame_count: 8
cell_width: 271
global_foot_y: 498
max_foot_baseline_drift_px: 2
runtime_connected: false
approved_for_manifest_switch: false
```

脚底基线通过初筛，最大偏差只有 2px。问题在于每一帧角色在 cell 内的横向中心不同，原始图不能直接切入运行时。

## 下一步建议

1. 编写归一化脚本，将 8 帧按底部锚点重新居中到固定 frame size。
2. 输出归一化后的透明帧目录和 preview sheet。
3. 再次计算中心漂移和脚底基线。
4. 归一化通过后，再制作 `player_warrior_body_down_run_v1`。
