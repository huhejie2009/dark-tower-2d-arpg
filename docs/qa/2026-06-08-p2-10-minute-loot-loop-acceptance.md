# P2 10 分钟刷宝目标检查

日期：2026-06-08  
阶段：P2 战斗手感与刷宝驱动  
目标时长：10 分钟  
素材原则：本轮不新增代码生成素材，重点检查刷宝、换装、升级、楼层推进是否形成连续动机。

## 通过规则

- 至少试玩 10 分钟。
- P0 阻塞缺陷必须为 0。
- 完整回归必须通过，并输出 `ALL_NEW_PROJECT_REGRESSION_OK`。
- 主项目 headless 启动退出码必须为 0。
- 10 分钟内应形成「清层 -> 掉落 -> 比较 -> 换装/升级 -> 继续下一层」的闭环。

## 建议记录字段

| 字段 | 目标值 | 说明 |
| --- | ---: | --- |
| `minutes_played` | 10 | 有效试玩时长。 |
| `floors_cleared` | 3 | 10 分钟内至少清 3 层。 |
| `items_picked` | 8 | 拾取物品数量，材料/货币/装备都算。 |
| `equipment_picked` | 1 | 至少拾取 1 件装备。 |
| `upgrade_candidates_seen` | 1 | 至少看到 1 次升级候选或明确推荐。 |
| `equipment_changes` | 1 | 至少实际换装 1 次。 |
| `skill_upgrades` | 1 | 至少完成 1 次技能升级或形成明确可升级目标。 |
| `p0_defects` | 0 | 阻塞缺陷为 0。 |
| `p1_defects` | <= 2 | 严重体验问题不超过 2 个。 |
| `regression_passed` | true | 完整回归通过。 |
| `headless_exit_zero` | true | 主项目 headless 启动退出码为 0。 |

## 人工试玩路线

1. 从主城进入战斗。
2. 连续推进至少 3 层，期间不要刻意绕开掉落。
3. 每次拾取装备后打开背包，看推荐、来源、质量标签和对比摘要是否能指导判断。
4. 至少装备一件更强装备。
5. 获得技能点后打开背包技能区，确认能看懂消耗、收益和阻塞原因。
6. 主动经历一次死亡或低血量回城，确认节奏不会中断存档和背包状态。
7. 记录 10 分钟内是否想继续刷下一层，以及卡住的原因。

## 服务化验收

`P2LootLoopAcceptanceService.evaluate_metrics(metrics)` 会输出：

- `passed`
- `completion_ratio`
- `failed_items`
- `gates_passed`
- `summary_text`
- `next_focus`
- `next_actions`

这份 payload 后续可以接入 QA 面板、调试 HUD、试玩报告生成器或可视化图表。
