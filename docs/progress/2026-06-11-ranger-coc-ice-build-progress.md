# 游侠寒冰 CoC 构筑进度

日期：2026-06-11

## 完成

- 新增 `ranger_ice_shot` 寒冰射击与 `ice_lance` 冰矛技能定义。
- 新增 `TriggerRuleService`，支持寒冰射击暴击触发冰矛、0.30 秒触发冷却和防循环规则。
- 游侠基础攻击切换为寒冰射击。
- `Player2D.cast_basic()` 返回暴击、触发技能、触发原因和触发命中信息。
- 新增 `AutoCombatController`，提供挂机模式最小自动索敌、移动和攻击意图。
- `Game2D` 支持 `manual` / `auto` 控制模式测试入口；两种模式共用同一套技能执行规则。
- 新增游侠 CoC 天赋节点：暴击、触发冷却恢复、冰霜伤害、冰矛分裂。
- 新增天赋重置接口，重置会退还技能点并移除节点提供的属性。
- 新增 `GemSocketService`，支持宝石孔、宝石镶嵌、取下和加成聚合。
- 新增首版宝石：寒霜、精准、迅捷、穿透、分裂。
- 装备总属性和装备评分接入冰霜、攻速、触发冷却恢复、冰矛穿透、冰矛分裂等 CoC 相关字段。
- 游侠掉落和 Boss 奖励会生成部分 CoC 相关词条。
- 装备对比和背包详情会解释游侠 CoC 词条，例如“更频繁触发冰矛”“增强寒冰射击和冰矛”“冰矛穿透”。

## 新增回归

- `regression_ranger_coc_trigger_service.gd`
- `regression_ranger_coc_player_cast.gd`
- `regression_auto_combat_controller.gd`
- `regression_game2d_auto_combat_mode.gd`
- `regression_ranger_coc_skill_nodes.gd`
- `regression_gem_socket_service.gd`
- `regression_ranger_coc_equipment_stats.gd`
- `regression_ranger_coc_compare_reasons.gd`

## 验证

使用 Godot：

```text
D:\Godot\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe
```

已通过：

- `FOCUSED_RANGER_COC_ICE_BUILD_OK`
- `RANGER_COC_FOCUSED_AND_IMPACTED_OK`
- `ALL_NEW_PROJECT_REGRESSION_OK COUNT 121`
- `NEW_PROJECT_SCENE_BOOT_ALL_OK`

覆盖的影响面包括：

- 角色创建。
- 技能节点成长。
- 基础攻击升级。
- 装备评分。
- 装备对比摘要。
- 物品实例 schema。
- 背包装备操作。
- Game2D 输入契约。
- 楼层模板生成。
- 四个主场景启动。

Godot headless 退出时仍会打印项目已知的 `ObjectDB instances leaked` / `resources still in use` 警告；全量回归中 `godot_ai` 插件也会输出部分解析警告文本，但测试脚本整体退出码为 0，按非阻断处理。

## 后续建议

1. 为寒冰射击和冰矛增加更明确的弹道视觉、冰霜命中特效和触发提示。
2. 给挂机模式增加玩家可见开关和基础 UI 状态提示。
3. 扩展自动拾取、传送门推进和危险规避策略。
4. 做 10 分钟“挂机 + 手操接管”混合刷图验收。
5. 宝石镶嵌已接入背包 UI；下一步补充宝石选择、替换和取下操作。
