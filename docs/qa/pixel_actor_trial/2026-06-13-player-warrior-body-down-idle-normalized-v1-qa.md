# 玩家战士 Body-Only Down Idle Normalized v1 QA

日期：2026-06-13

## 目标

将 `player_warrior_body_down_idle_candidate_v1.png` 从原始生成帧条归一化为可进入引擎试装的制作规格候选，重点验证脚底锚点、横向中心和透明帧格是否稳定。

## 产物

- normalized_strip: `res://assets/generated/actors/candidates/player_warrior_body_down_idle_normalized_v1.png`
- preview: `res://docs/qa/pixel_actor_trial/player_warrior_body_down_idle_normalized_v1_baseline_preview.png`
- metrics: `res://docs/qa/pixel_actor_trial/player_warrior_body_down_idle_normalized_v1_metrics.json`
- tool: `res://tools/qa_normalize_player_warrior_body_idle_candidate.gd`

## 规格

- frame_count: 8
- frame_size: 192x320
- anchor: bottom_center
- anchor_y: 288
- weapon_layer_mode: body_only_no_weapon
- runtime_connected: false
- approved_for_manifest_switch: false

## 检查结果

- max_foot_baseline_drift_px: 0
- max_center_drift_px: 0.5
- 每帧保留透明背景。
- 每帧脚底落在同一条 baseline。
- 每帧角色主体居中，适合后续制作独立武器层和 weapon socket 轨道。

## 结论

该候选已经通过归一化静态 QA，可以进入下一步“隔离试装场景”验证。但它仍不能直接切到正式玩家 manifest，因为当前只覆盖 down idle 一个动作，没有 run、attack、death，也没有 4 方向动作集。

下一步建议：

1. 建立 isolated actor preview scene，只加载该归一化帧条，不影响正式游玩。
2. 用相同规格制作 down run body-only 候选，要求最少 8 帧、清晰换脚。
3. 同步定义 weapon socket 轨道格式，避免未来换武器时返工。
