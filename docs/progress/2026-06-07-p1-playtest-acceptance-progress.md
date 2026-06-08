# 2026-06-07 P1 内部试玩验收清单进度

## 对应 ROADMAP

- 阶段：P1 可试玩 UI 与装备闭环
- 类型：P1 收尾门禁 / 进入 P2 前验收

## 本轮目标

在进入 P2「战斗手感与刷宝驱动」前，把 P1 的人工试玩验收标准固化下来。验收清单不生成新素材，不引入代码生成资产，只沉淀系统接口、测试门禁和人工试玩标准。

## 已完成

- 新增 `scripts/data/PlaytestAcceptanceService.gd`
  - `build_phase_acceptance("P1")`
  - `evaluate_phase_report("P1", report)`
- 新增 P1 验收数据：
  - 存档/角色。
  - 背包。
  - 装备。
  - 掉落提示。
  - 死亡结算。
  - 暂停/回城。
  - 楼层稳定。
  - 回归门禁。
- 新增人工试玩文档：
  - `docs/qa/2026-06-07-p1-internal-playtest-acceptance.md`
- ROADMAP 另存更新版：
  - `docs/planning/2026-06-07-dark-tower-2d-arpg-production-roadmap-updated-p1-acceptance.xlsx`

## 通过规则

- P0 阻塞缺陷必须为 0。
- P1 严重缺陷不超过 2 个。
- 至少完成 30 分钟内部试玩。
- 完整回归通过。
- 主项目 headless 启动退出码为 0。
- 不清除玩家存档。

## 回归覆盖

新增：

- `tests/regression/regression_p1_playtest_acceptance_service.gd`

已验证：

- `NEW_PROJECT_P1_PLAYTEST_ACCEPTANCE_SERVICE_OK`

## 下一步建议

先按 `docs/qa/2026-06-07-p1-internal-playtest-acceptance.md` 做一轮人工试玩。如果人工验收没有 P0，且 P1 不超过 2 个，就进入 P2：

- T-006 玩家攻击手感第一轮。
- 不新增代码生成素材。
- 优先做手感数据、状态接口、命中反馈、输入缓冲、冷却/前后摇等系统层能力。
