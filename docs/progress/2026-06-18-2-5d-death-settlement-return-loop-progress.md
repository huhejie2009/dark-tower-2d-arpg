# 2026-06-18 2.5D Death Settlement / Return Loop Progress

## 本轮目标

让当前主流程使用的 2.5D 进塔战斗具备“一局失败后能结算并安全回城”的基础闭环。

## 已完成

- `Prototype2_5DCombatRoom` 接入 `DeathSettlementService`。
- 敌人攻击冷却完成后会对玩家造成确定性伤害。
- 玩家血量归零后进入一次性死亡状态：
  - 停止玩家移动和攻击表现。
  - 关闭暂停层和背包层。
  - 打开死亡结算层。
  - 暂停整棵场景树，阻止继续受击、移动、攻击、开背包或开暂停菜单。
- 死亡结算复用现有结算文本结构：
  - 楼层信息。
  - 击杀数。
  - 本层拾取列表。
  - Boss 奖励摘要。
- 死亡时保存回城状态：
  - 背包和装备保留。
  - 玩家回城保存为半血。
  - 不清除玩家存档。
- 新增测试接口：
  - `force_enemy_attack_player_for_test(index)`
  - `build_death_settlement_snapshot_for_test()`
  - `_return_to_town_after_death_for_test()`
- 新增回归：
  - `tests/regression/regression_prototype_2_5d_death_settlement_return_loop.gd`

## 验收标准

- 低血量玩家被敌人攻击后，2.5D 场景显示死亡结算。
- 死亡结算期间游戏暂停，战斗输入和菜单输入被阻止。
- 重复攻击不会重复触发死亡结算。
- 存档中的玩家血量变为最大血量的一半，背包和装备数据不丢失。
- 测试回城钩子会解除暂停并保持半血保存状态。

## 未做内容

- 这轮没有新增或生成任何美术素材。
- 死亡结算 UI 仍是功能性面板，后续需要统一到最终暗黑风 UI。
- 还没有做死亡动画延迟、音效、失败奖励惩罚或复活点选择。
