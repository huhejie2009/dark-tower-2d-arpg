# 2026-06-07 战斗手感接口第一轮进度

## 本轮目标

按照 ROADMAP P2 / T-006「玩家攻击手感第一轮」推进。当前重点不是制作或生成新素材，而是把攻击节奏拆成稳定、可测试、可被正式素材复用的系统接口。

## 已完成

- 新增 `CombatFeelService`，统一提供基础攻击的前摇、命中帧、后摇、输入缓存、打击停顿、冷却和动画阶段配置。
- `Player2D` 接入攻击手感 profile，攻击状态从单一冷却扩展为 `ready / windup / active / recovery`。
- 左键连续攻击时，第二次输入会记录为 buffered attack，为后续连击、取消窗口、音效和镜头反馈留接口。
- 攻击结果字典新增 `accepted`、`buffered`、`attack_phase`、`windup`、`hit_frame`、`recovery`、`input_buffer`、`hit_stop` 字段。
- 保留现有即时命中结算，避免本轮改动影响敌人死亡、掉落、爬塔推进和旧回归。
- 未加入代码生成素材；本轮只做系统与接口。

## 新增/更新验证

- `regression_combat_feel_service.gd`
- `regression_player_attack_feel_state.gd`
- 聚焦回归标记：`FOCUSED_P2_COMBAT_FEEL_REGRESSION_OK`

## ROADMAP 更新

- 新增版本：`docs/planning/2026-06-07-dark-tower-2d-arpg-production-roadmap-updated-p2-combat-feel.xlsx`
- T-006 状态更新为「第一轮完成」。
- P2 状态更新为「进行中」，完成率更新为 15%。

## 后续衔接

下一步推荐进入 P2 的战斗反馈层：

1. 受击反馈与怪物硬直接口：让命中不只是扣血，还能被动画、音效、闪白、击退和掉血数字复用。
2. 敌人行为差异第一轮：近战、弓手、守卫分开距离策略和攻击读条。
3. 正式素材接入时，动画资源只需要对齐 `idle / run / attack / death` 与方向 manifest，不需要改战斗逻辑。
