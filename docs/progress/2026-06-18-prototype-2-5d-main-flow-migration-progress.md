# 2026-06-18 2.5D 主流程迁移第一阶段进度

## 本轮目标

在用户确认 2.5D 原型方向可接受后，开始将 2.5D 战斗房从隔离原型迁移为主进塔路径。第一阶段优先保证主城进塔、玩家数据、楼层请求和进度保存可以贯通。

## 已完成

- `GameConstants.ACTIVE_GAME_SCENE` 继续指向 `res://scenes/prototypes/Prototype2_5DCombatRoom.tscn`。
- `GameConstants.GAME_2D_SCENE` 保留 `res://scenes/Game2D.tscn`，作为 legacy fallback 和回归参照。
- `Prototype2_5DCombatRoom` 新增主流程桥：
  - 读取 `SaveManager.get_active_player_data()`。
  - 消费 `TowerRunStartService.consume_start_floor(player_data)`。
  - 维护 `current_floor`。
  - 按 `E` 在清怪开门后进入下一层。
  - 下一层时保存 `highest_floor`，重置出口并重建敌人。
  - 提供 `_return_to_town()` 和 `_return_to_town_for_test()` 保存桥。
- 新增 `build_main_flow_migration_snapshot_for_test()`，用于验证 2.5D 已具备主流程身份和回退路径。

## 新增回归

- `tests/regression/regression_prototype_2_5d_main_flow_migration_contract.gd`

验收内容：

- active game scene 指向 2.5D。
- legacy 2D scene 仍保留。
- 2.5D 场景能消费主城请求的最高楼层。
- 2.5D 场景能读取活动角色数据。
- 下一层会推进 `current_floor` 并保存最高层进度。
- 回城测试桥会保存当前进度。

## 当前迁移边界

本轮完成的是主流程入口和楼层进度桥，尚未把旧 `Game2D` 的全部系统搬入 2.5D。后续仍需迁移：

1. HUD 血量、魔力、经验、楼层目标显示。
2. 背包/装备窗口打开时暂停战斗。
3. 掉落、拾取、奖励、经验桥。
4. 死亡结算和回城按钮。
5. 楼层模板、敌人类型、boss 房和连续楼层节奏。

## 后续建议

下一阶段推荐做“2.5D HUD 与暂停/背包桥接”，因为这是玩家实际试玩时最先感知到的完整游戏感差异。
