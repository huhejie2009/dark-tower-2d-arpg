# 2026-06-07 死亡结算服务化进度

## 对应 ROADMAP

- 阶段：P1 可试玩 UI 与装备闭环
- 任务：T-005 死亡结算细化

## 本轮目标

把死亡结算内容从 `Game2D` 的字符串拼接迁移到独立服务，让场景只负责展示。后续可以在不改核心结算逻辑的前提下扩展复活选择、失败惩罚、收益统计、结算动画和图标化 UI。

## 已完成

- 新增 `scripts/data/DeathSettlementService.gd`
  - `build_death_settlement(context)`
  - 输出结构化结算数据：
    - 楼层文本。
    - 战斗文本。
    - 拾取文本。
    - Boss 奖励文本。
    - 总结文本。
    - 下一步行动文本。
    - `sections` 数组，供后续结算页动态布局复用。
- `Game2D` 已接入服务：
  - `_refresh_death_settlement_sections()`
  - `_build_death_summary_text()`
  - `_build_boss_reward_summary()`
- 保留旧测试接口：
  - `_refresh_death_settlement_sections_for_test()`
  - `_build_death_summary_text_for_test()`
  - 新增 `_build_death_settlement_for_test()`

## 体验与设计收益

- 死亡结算明确展示：
  - 死亡楼层与房间模板。
  - 本层击杀数。
  - 本层拾取物。
  - Boss 奖励。
  - 回城半血。
  - 背包和装备保留。
- 不清理玩家存档。
- 为后续死亡结算 UI 重排、复活系统、失败惩罚和收益统计留出统一接口。

## 回归覆盖

新增：

- `tests/regression/regression_death_settlement_service.gd`

已验证：

- `NEW_PROJECT_DEATH_SETTLEMENT_SERVICE_OK`
- `FOCUSED_DEATH_SETTLEMENT_REGRESSION_OK`

## ROADMAP 更新

已另存更新版：

- `docs/planning/2026-06-07-dark-tower-2d-arpg-production-roadmap-updated-p1-death-settlement.xlsx`

更新内容：

- T-005 状态改为 `已完成`。
- P1 完成率更新为 `78%`。

## 下一步建议

P1 的核心 UI/装备闭环已经接近收束。下一轮建议做 P1 收尾：

- 打一轮 30 分钟内部试玩验收清单。
- 修 P1 体验缝隙：提示条停留时间、装备槽稀有边框、死亡结算按钮文案。
- 然后进入 P2：战斗手感与刷宝驱动。
