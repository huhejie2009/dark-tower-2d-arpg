# 2026-06-18 2.5D Ranged / Boss Behavior Bridge Progress

## 本轮目标

让 2.5D 楼层模板里的敌人不只是“名字和数量不同”，而是开始有可感知的行为差异。

## 已完成

- `shadow_archer` 接入第一版远程行为：
  - 玩家太近时后退。
  - 玩家在射程内时进入 `ranged_attack`。
  - 远程攻击以 `projectile` 类型记录，并会对玩家造成伤害。
- 普通近战敌人继续走原有追击/近战攻击逻辑。
- `tower_gatekeeper` 接入第一版 Boss slam 行为接口：
  - 生成 `GatekeeperSlamWarning` 占位警示圈。
  - 警示圈带有 `vfx_role = gatekeeper_slam_warning` 元数据，后续可以替换成真实技能特效。
  - 结算时如果玩家在半径内，会造成伤害。
- 新增 2.5D 行为测试接口：
  - `build_enemy_behavior_snapshot_for_test()`
  - `tick_enemy_behavior_for_test(delta)`
  - `force_boss_slam_for_test(index)`
  - `resolve_boss_slam_for_test()`
- 新增回归：
  - `tests/regression/regression_prototype_2_5d_ranged_boss_behavior_bridge.gd`

## 验收标准

- 第 3 层弓手在玩家贴近时会后退。
- 弓手在合适距离会远程攻击并扣玩家血量。
- 第 5 层 Boss 可以生成可读警示圈。
- Boss slam 结算后，警示圈隐藏，范围内玩家受伤。
- 2.5D 现有移动、攻击、掉落、死亡、楼层模板和视觉测试不回退。

## 未做内容

- 没有新增或生成任何美术素材。
- 弓手远程攻击暂时是逻辑命中，还没有真正飞行投射物。
- Boss slam 警示是程序占位圆，不是最终特效。
- Boss 的短冲锋、连招、阶段变化尚未迁移到 2.5D。
