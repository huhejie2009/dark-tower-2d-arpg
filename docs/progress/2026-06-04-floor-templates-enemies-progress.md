# 2026-06-04 楼层节奏与敌人类型进度

## 本轮目标

在已经具备主菜单、角色槽、主城、战斗、背包/装备、暂停和死亡结算的基础上，继续推进“10 到 20 分钟可试玩”的内容差异：

1. 增加 3 到 5 个楼层节奏模板。
2. 增加普通敌人的类型差异。
3. 保持连续楼层、清层传送门、死亡结算和 UI 回归稳定。

## 已完成内容

### 楼层模板规则

新增 `scripts/rules/FloorRules.gd`。

当前实现 5 种模板循环：

- `standard_clear`：标准清怪层。
- `dense_room`：小房间高密度近战层。
- `ranged_pressure`：远程压制层。
- `guardian_mix`：守卫混编层。
- `elite_preview`：精英雏形预览层。

`Game2D.gd` 现在通过 `FloorRules.build_floor_template(current_floor)` 生成敌人，而不是固定生成同一组敌人。

### 敌人类型

新增三类普通敌人：

- `rot_melee`
  - 标准近战追击敌人。
  - 中等血量、中等速度、近战攻击。
- `shadow_archer`
  - 远程压制敌人。
  - 低血量、较长攻击距离、使用简化投射物攻击。
- `tower_guardian`
  - 高血量守卫敌人。
  - 低速度、高血量、较高近战伤害。

`Enemy2D.gd` 新增 `apply_enemy_data(data)`，用于从规则层应用血量、速度、攻击距离、攻击冷却、颜色和投射物行为。

### 远程攻击

- `shadow_archer` 使用轻量 `Area2D` 投射物。
- 投射物命中玩家时调用 `take_damage()`。
- 投射物带简易视觉占位，并在短时间后自动释放。

### 场景生成测试入口

`Game2D.gd` 新增 `_apply_floor_template_for_test(floor)`，仅用于回归脚本指定楼层并验证生成结果。

## 新增回归测试

- `regression_floor_templates.gd`
  - 验证 1 到 10 层覆盖 5 种模板。
  - 验证模板包含有效敌人类型。
- `regression_enemy_type_stats.gd`
  - 验证远程敌人射程高于近战。
  - 验证守卫血量更高且移速更低。
  - 验证 `Enemy2D.apply_enemy_data()` 能正确应用远程敌人数据。
- `regression_game2d_floor_template_spawn.gd`
  - 验证第 3 层生成远程压制敌人。
  - 验证第 4 层生成守卫敌人。

## 验证结果

已使用 Godot 4.6.2 headless 验证：

- `NEW_PROJECT_FLOOR_TEMPLATES_OK`
- `NEW_PROJECT_ENEMY_TYPE_STATS_OK`
- `NEW_PROJECT_GAME2D_FLOOR_TEMPLATE_SPAWN_OK`
- `ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动退出码：`0`
- 残留 Godot 测试进程：未发现

## 当前限制

- 精英层目前只是精英雏形，尚未实现词缀技能或死亡爆炸。
- 远程投射物是简化实现，还没有命中特效、预警线或弹道音效。
- 楼层模板还没有房间布局、障碍物和奖励差异。
- Boss 层尚未实现。

## 下一步建议

1. 实现精英词缀第一版：快速、坚韧、死亡爆裂。
2. 做第 5 层小 Boss：塔门守卫。
3. 给死亡结算加入击杀数、拾取列表和本层模板名称。
4. 给远程敌人投射物增加更清晰的视觉预警。
5. 开始楼层奖励差异：精英层和 Boss 层给更高掉落权重。
