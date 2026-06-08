# 2026-06-05 基础技能点消费进度

## 本次目标

让升级获得的技能点先有一个稳定可用的消费出口，避免玩家升级后只能看到 SP 数字但不能成长。

## 已完成

- 在 `PlayerDataService` 中新增基础攻击训练节点：
  - 节点 ID：`basic_attack_training`
  - 最高等级：5
  - 每级消耗 1 点技能点
  - 每级提升 `attack_damage +3`
- `normalize_player_data()` 继续兼容旧存档数据，缺失或异常的 `unlocked_skill_nodes` 会安全补成字典。
- 在背包/装备窗口右侧加入 `Skills` 区：
  - 显示当前 SP。
  - 显示基础攻击训练等级。
  - 提供 `Upgrade Basic Attack` 按钮。
  - 没有技能点或达到满级时按钮禁用。
- 点击升级后会：
  - 消耗 1 点技能点。
  - 提高基础攻击伤害。
  - 更新窗口统计。
  - 通过 `player_data_changed` 继续走现有玩家数据同步链路。

## 新增回归

- `regression_skill_point_basic_attack_upgrade.gd`
  - 覆盖成功升级、无技能点失败、满级失败。
- `regression_inventory_skill_upgrade_ui.gd`
  - 覆盖背包窗口技能点摘要、升级按钮、点击后数据变更事件。

## 验证结果

- `NEW_PROJECT_SKILL_POINT_BASIC_ATTACK_UPGRADE_OK`
- `NEW_PROJECT_INVENTORY_SKILL_UPGRADE_UI_OK`
- `ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动：`HEADLESS_EXIT 0`
- 启动后未发现残留 Godot 测试进程。

## 边界说明

- 本次没有清除或迁移玩家存档。
- 本次没有回到旧 3D 项目，也没有恢复 POLYGON 资源。
- 本次只做第一版可用技能点消费入口，还不是完整技能树。
- 后续可继续扩展为职业技能树、技能图标、分支节点和更清晰的中文 UI 文案。
