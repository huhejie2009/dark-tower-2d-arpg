# 2026-06-04 精英词缀与第 5 层 Boss 进度

## 本轮目标

在已有楼层模板和三类普通敌人的基础上，继续增加第一版精英和 Boss 内容：

1. 精英词缀第一版：快速、坚韧、死亡爆裂。
2. 第 5 层小 Boss：塔门守卫。
3. 保持完整回归、连续楼层稳定性和场景启动稳定。

## 已完成内容

### 精英词缀

`FloorRules.gd` 新增可组合精英词缀：

- `fast`
  - 提升移动速度。
  - 略微缩短攻击冷却。
- `tough`
  - 提升最大生命。
- `death_burst`
  - 死亡时生成短暂范围伤害区域。
  - 当前带红色圆环占位视觉。

`Enemy2D.gd` 新增并保存：

- `is_elite`
- `elite_affixes`
- `death_burst`
- `death_burst_damage`
- `death_burst_radius`

### Boss 层

第 5、10、15 等 5 的倍数楼层现在使用 `boss_gatekeeper` 模板。

Boss 层包含：

- `tower_gatekeeper`：塔门守卫 Boss。
- 两个近战随从。

`tower_gatekeeper` 当前定位：

- 高生命。
- 低速近战压迫。
- 比普通守卫更高伤害。
- 标记 `is_boss = true`。
- 体型放大。

### 楼层模板循环调整

Boss 层插入后，非 Boss 楼层改为单独计数循环普通模板，避免 `elite_preview` 被第 5 层 Boss 挤掉。

当前节奏：

- 1 层：标准清怪。
- 2 层：高密度近战。
- 3 层：远程压制。
- 4 层：守卫混编。
- 5 层：Boss。
- 6 层：精英预览。
- 后续继续循环。

## 新增/调整回归测试

新增：

- `regression_elite_affixes.gd`
- `regression_boss_floor_template.gd`
- `regression_game2d_boss_spawn.gd`
- `regression_death_burst_affix.gd`

调整：

- `regression_floor_templates.gd`
  - 从 10 层覆盖改为 15 层覆盖。
  - 新增 `boss_gatekeeper` 模板断言。
  - 新增 `tower_gatekeeper` 敌人类型断言。

## 验证结果

已使用 Godot 4.6.2 headless 验证：

- `NEW_PROJECT_ELITE_AFFIXES_OK`
- `NEW_PROJECT_BOSS_FLOOR_TEMPLATE_OK`
- `NEW_PROJECT_GAME2D_BOSS_SPAWN_OK`
- `NEW_PROJECT_DEATH_BURST_AFFIX_OK`
- `NEW_PROJECT_FLOOR_TEMPLATES_OK`
- `ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动退出码：`0`
- 残留 Godot 测试进程：未发现

## 当前限制

- Boss 还没有专属技能，当前是强化近战压迫型。
- 死亡爆裂已有范围和视觉，但还没有预警延迟。
- 精英词缀还没有在 HUD 或死亡结算里展示。
- Boss 掉落和楼层奖励还没有特殊化。

## 下一步建议

1. 给 Boss 加第一版技能：扇形重击或短冲锋。
2. 给死亡爆裂增加 0.4 秒预警圈，再造成伤害。
3. Boss 层奖励特殊化：至少一件魔法装备、更高金币和水晶概率。
4. 死亡结算展示本层模板、击杀数和拾取列表。
5. 给精英/Boss 增加更清晰的名称条或 HUD 提示。
