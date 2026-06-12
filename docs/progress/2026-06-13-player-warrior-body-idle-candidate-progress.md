# 2026-06-13 玩家战士身体 Idle 候选进度

## 本轮目标

按动作分离与武器分层管线，生成第一条玩家身体素材候选：下方向 idle，8 帧，无武器，不接入实机。

## 已完成

- 生成下方向 idle 绿幕源图：
  - `docs/concepts/pixel_actor_trial/player_warrior_body_down_idle_candidate_v1_green.png`
- 生成透明候选图：
  - `assets/generated/actors/candidates/player_warrior_body_down_idle_candidate_v1.png`
- 新增 QA：
  - `docs/qa/pixel_actor_trial/2026-06-13-player-warrior-body-down-idle-candidate-v1-qa.md`
- 新增回归：
  - `tests/regression/regression_player_warrior_body_idle_candidate.gd`

## 当前结论

该候选满足“身体无武器”和“单动作不混合”的基础要求。它可以进入切格和锚点检查，但还不能接入正式 manifest。

## 质量观察

- 动作：idle 结构成立，但呼吸变化偏弱。
- 武器：没有烘焙武器，符合后续换装方向。
- 像素：颗粒仍偏软，下一轮提示词需要继续强调硬边像素块。
- 透明：透明候选已生成，需后续检查边缘和脚底基线。

## 下一步建议

1. 编写 8 等分切格与脚底基线分析脚本。
2. 输出带 cell 框和 baseline 的 QA 预览图。
3. 如果锚点通过，再制作 `player_warrior_body_down_run_v1`。
