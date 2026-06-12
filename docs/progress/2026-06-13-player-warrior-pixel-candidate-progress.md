# 2026-06-13 玩家战士像素候选素材进度

## 本轮目标

继续按像素角色生产包推进，尝试制作玩家战士 4 向候选图，并在发现 4 向整表不稳定后，改为更可靠的单方向 20 帧生产策略。

## 已完成

- 生成并归档 4 向玩家战士候选图：
  - `docs/concepts/pixel_actor_trial/player_warrior_4dir_pixel_sheet_candidate_v1.png`
- 新增 4 向候选 QA：
  - `docs/qa/pixel_actor_trial/2026-06-13-player-warrior-4dir-candidate-v1-qa.md`
- 生成玩家战士下方向 20 帧绿幕小条：
  - `docs/concepts/pixel_actor_trial/player_warrior_down_pixel_strip_candidate_v1_green.png`
- 使用本地 chroma-key 移除流程生成透明候选：
  - `assets/generated/actors/candidates/player_warrior_down_pixel_strip_candidate_v1.png`
- 新增下方向小条 QA：
  - `docs/qa/pixel_actor_trial/2026-06-13-player-warrior-down-strip-candidate-v1-qa.md`
- 新增回归：
  - `tests/regression/regression_player_warrior_pixel_candidate_qa.gd`
  - `tests/regression/regression_player_warrior_down_strip_candidate.gd`

## 判断

完整 4 向 80 帧一次生成不够稳定，容易缺帧或动作漂移。单方向 20 帧小条更符合可控生产流程，后续应该先把下方向切格和锚点跑通，再做其他方向。

## 未接入项

- 未修改运行时 manifest。
- 未替换当前玩家实机素材。
- 未切换 `direction_mode`。
- 未清理玩家存档。

## 下一步建议

1. 编写切格/锚点检查脚本，读取下方向透明候选并输出 20 格边界数据。
2. 生成带锚线的预览图，人工检查脚底稳定性。
3. 若锚点可接受，再建立一个只用于测试的下方向玩家显示 manifest。
