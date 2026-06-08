# 2026-06-07 敌人行为差异第一轮进度

## 本轮目标

继续推进 ROADMAP P2 / T-007「敌人行为差异」。目标是把敌人 AI 从单一追击攻击，拆成可测试、可调参、可被后续动画/VFX/UI 复用的行为 profile。

本轮不生成素材，不改已有 IMAGE2 素材引用。

## 已完成

- 新增 `EnemyBehaviorService`，统一提供敌人行为 profile。
- 当前覆盖：
  - `rot_melee`：近战追击者，快速贴近。
  - `shadow_archer`：远程风筝者，太近会后撤，合适距离读条射击。
  - `tower_guardian`：守卫压迫者，速度慢、承诺距离更远、攻击前摇更明显。
  - `tower_gatekeeper`：Boss 压迫者，读条更长，为 Boss 技能预警保留节奏空间。
- `Enemy2D` 接入 `approach / retreat / attack` 行为意图。
- `Enemy2D` 新增攻击读条状态，攻击前会进入短暂 windup，而不是瞬间造成伤害。
- 新增测试出口：
  - `get_behavior_profile_for_test`
  - `evaluate_behavior_intent_for_test`
  - `get_behavior_state_for_test`

## 新增/更新验证

- `regression_enemy_behavior_service.gd`
- `regression_enemy_behavior_state.gd`
- 聚焦验证：`FOCUSED_P2_ENEMY_BEHAVIOR_REGRESSION_OK`

## ROADMAP 更新

- 新增版本：`docs/planning/2026-06-07-dark-tower-2d-arpg-production-roadmap-updated-p2-enemy-behavior.xlsx`
- T-007 状态更新为「第一轮完成」。
- P2 完成率更新到 35%。

## 后续衔接

推荐下一步进入 T-008「掉落质量曲线」：

1. 建立按楼层、敌人等级、Boss/精英来源区分的掉落质量 profile。
2. 让掉落服务产出可统计的结果，避免感觉上“刷了很多但没目标”。
3. 后续装备对比、掉落光柱、稀有音效都从同一份掉落 payload 读取，不把表现写进掉落生成逻辑。
