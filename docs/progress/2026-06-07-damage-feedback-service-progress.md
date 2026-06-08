# 2026-06-07 受击反馈接口进度

## 本轮目标

继续推进 ROADMAP P2。当前重点是把「受击」从单纯扣血扩展为可复用的反馈数据层，为后续正式动画、VFX、音效、飘字和镜头反馈留接口。

本轮不生成素材，也不把视觉表现写死到素材里。

## 已完成

- 新增 `DamageFeedbackService`，统一产出受击反馈 payload。
- 反馈 payload 包含：
  - `impact_level`：light / medium / heavy / lethal
  - `stagger_duration`：硬直时间
  - `knockback_distance`：击退距离
  - `hit_flash_duration`：闪白时间
  - `camera_shake`：镜头反馈强度
  - `damage_number`：飘字请求
  - `vfx_event` / `audio_event`：后续正式资源挂接事件
- `Enemy2D` 接入受击反馈：
  - 普通怪、精英、Boss 使用不同抗性系数。
  - 受击时记录反馈状态并执行服务化击退。
  - 受击硬直期间短暂停止行动。
- `Player2D` 接入受击反馈：
  - 玩家受伤时记录反馈状态。
  - 受击时保留镜头震动参数接口。
  - 受击硬直期间移动速度短暂降低。
- 玩家和敌人都提供 `get_damage_feedback_state_for_test` 与 `tick_damage_feedback_for_test` 测试出口。

## 新增/更新验证

- `regression_damage_feedback_service.gd`
- `regression_actor_damage_feedback_state.gd`
- 聚焦验证：`FOCUSED_P2_DAMAGE_FEEDBACK_REGRESSION_OK`

## ROADMAP 更新

- 新增版本：`docs/planning/2026-06-07-dark-tower-2d-arpg-production-roadmap-updated-p2-damage-feedback.xlsx`
- P2 完成率更新到 25%。
- T-006 状态更新为「第一轮完成+受击反馈接口」。

## 后续衔接

推荐下一步进入 T-007「敌人行为差异」：

1. 建立 `EnemyBehaviorService` 或等价行为 profile，区分近战、弓手、守卫、Boss 的距离策略。
2. 敌人攻击读条与预警接口接入现有 attack animation / warning VFX。
3. 受击反馈 payload 的 `vfx_event`、`audio_event`、`damage_number`、`camera_shake` 可在后续 HUD/VFX/Audio 层统一消费。
