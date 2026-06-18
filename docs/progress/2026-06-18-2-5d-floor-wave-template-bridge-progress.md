# 2026-06-18 2.5D Floor Wave Template Bridge Progress

## 本轮目标

让当前主流程使用的 2.5D 进塔战斗不再是固定房间、固定两个敌人的原型循环，而是开始读取已有楼层模板，形成可扩展的爬塔节奏。

## 已完成

- `Prototype2_5DCombatRoom` 接入：
  - `FloorRules`
  - `RoomObjectiveService`
- 2.5D 运行时现在通过 `FloorRules.build_floor_template(current_floor)` 生成敌人波次。
- 已支持的模板节奏：
  - `standard_clear`
  - `dense_room`
  - `ranged_pressure`
  - `guardian_mix`
  - `elite_preview`
  - `boss_gatekeeper`
- 2D 楼层模板坐标通过本地映射转换到 2.5D XZ 平面，并限制在房间边界内。
- 敌人状态现在保留：
  - `enemy_type`
  - `display_rank`
  - `is_elite`
  - `is_boss`
  - 攻击伤害、攻击距离、攻击冷却
  - 原始 `enemy_data`
- 2.5D 敌人贴图 manifest 从楼层规则继承，并补齐 2.5D 需要的接口字段：
  - 身体与武器分层
  - 战斗特效分离
  - 接触阴影
- HUD 目标文本改为读取 `RoomObjectiveService` 的目标状态。
- 死亡结算中的模板 ID 改为读取当前楼层模板。
- 新增测试接口：
  - `build_floor_wave_snapshot_for_test()`
  - `_apply_floor_template_for_test(floor)`
- 更新旧 2.5D 回归中“固定两个敌人”的原型断言，使其改为按模板敌人数量验收。

## 验收标准

- 2.5D 第 1 层使用 `standard_clear`。
- 第 3 层使用 `ranged_pressure`，包含 `shadow_archer`。
- 第 4 层使用 `guardian_mix`，包含 `tower_guardian`。
- 第 5 层使用 `boss_gatekeeper`，包含 `tower_gatekeeper`，并被识别为 Boss 层。
- 每个模板敌人都会生成到 2.5D 房间边界内。
- 现有移动、攻击、死亡结算、HUD、掉落和视觉接地回归不回退。

## 未做内容

- 这轮没有新增或生成任何美术素材。
- 房间本身仍是灰盒/占位结构，没有做多房间预制体。
- 弓手仍复用近战式伤害结算，没有真正投射物。
- Boss 技能尚未迁移到 2.5D。
