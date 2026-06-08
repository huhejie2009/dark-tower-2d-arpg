# 2026-06-04 Boss 保底奖励与死亡结算详情进度

## 本轮目标

继续推进 Boss 层奖励和战斗结算体验：

1. 将 Boss 层 `guaranteed_magic_equipment` 标记接入实际奖励流程。
2. 清 Boss 层时把保底魔法装备加入当前角色背包。
3. 死亡结算显示本层模板、击杀数、拾取列表和 Boss 奖励信息。

## 已完成内容

### Boss 保底魔法装备

`EquipmentAffixRules.gd` 新增：

- `build_boss_clear_reward(floor, base_class)`

当前生成一件魔法品质 Boss 奖励装备：

- `template_id = boss_clear_reward`
- `rarity = magic`
- 按职业池设置 `equipment_pool`
- 基础词条包含攻击和生命
- 游侠、法师、侍僧会额外获得职业相关词条

`LootRules.gd` 新增：

- `generate_boss_clear_reward(floor, base_class)`

它把 Boss 奖励装备包装成背包可接收的掉落 payload。

### 清层奖励入背包

`Game2D.gd` 新增：

- `_build_floor_clear_rewards(floor, base_class)`
- `_apply_floor_clear_rewards_to_player(data, rewards)`

Boss 层清层时：

1. 读取 `TowerProgressService.build_floor_reward()`。
2. 如果奖励包含 `guaranteed_magic_equipment`，生成一件 Boss 保底魔法装备。
3. 把装备加入当前角色背包。
4. 保存当前角色快照。

### 死亡结算详情

`Game2D.gd` 新增本层统计：

- `floor_kill_count`
- `floor_pickup_names`
- `last_floor_rewards`

死亡结算现在显示：

- 当前楼层。
- 当前楼层模板 ID。
- 本层击杀数。
- 已拾取物品列表。
- Boss 奖励信息。
- 回城后半血提示。

## 新增回归测试

- `regression_boss_reward_inventory_bridge.gd`
  - 验证 Boss 奖励包含保底装备。
  - 验证保底装备进入玩家背包。
  - 验证装备品质为 magic 且模板为 `boss_clear_reward`。
- `regression_death_settlement_details.gd`
  - 验证死亡结算文本包含楼层模板。
  - 验证显示击杀数。
  - 验证显示拾取列表。
  - 验证显示 Boss 奖励提示。

## 验证结果

已使用 Godot 4.6.2 headless 验证：

- `NEW_PROJECT_BOSS_REWARD_INVENTORY_BRIDGE_OK`
- `NEW_PROJECT_DEATH_SETTLEMENT_DETAILS_OK`
- `ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动退出码：`0`
- 残留 Godot 测试进程：未发现

## 当前限制

- Boss 奖励装备已经入背包，但还没有专门的结算弹窗领取动画。
- 死亡结算是文本汇总，还没有图标化展示拾取物。
- Boss 奖励名称和词条仍是程序化占位。
- `LootRules.gd` 为了避免旧乱码补丁问题，掉落显示名已改成 ASCII 占位名。

## 下一步建议

1. 把死亡结算做成更像 ARPG 的结算窗口：击杀、拾取、奖励分区显示。
2. 给 Boss 保底装备加更明确的掉落光柱或结算图标。
3. 给 Boss 增加第二个技能：短冲锋。
4. 给精英/Boss 加名称条和词缀提示。
5. 开始补 2D 视觉表现：敌人区分、投射物预警、Boss 技能边界。
