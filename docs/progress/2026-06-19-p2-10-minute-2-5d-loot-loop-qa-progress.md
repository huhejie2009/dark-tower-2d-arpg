# 2026-06-19 P2 10 分钟 2.5D 刷宝闭环 QA 进度

## 目标

把当前主线 2.5D 爬塔运行时接入 P2 10 分钟刷宝验收模型，让“像不像一款游戏”可以被指标、报告和回归脚本持续检查。

## 已完成

- 新增 2.5D P2 QA 回归：`tests/regression/regression_prototype_2_5d_p2_loot_loop_qa_bridge.gd`。
- `Prototype2_5DCombatRoom` 现在记录：
  - 有效游玩时长
  - 清层数
  - 拾取物数量
  - 装备拾取数
  - 升级候选/成长机会
  - 换装次数
  - 死亡次数
  - 回归与 headless 启动门禁
- 新增 2.5D QA 快照：`build_p2_loot_loop_qa_snapshot_for_test()`。
- 新增测试钩子：
  - `set_p2_loot_loop_elapsed_seconds_for_test()`
  - `set_p2_loot_loop_verification_gates_for_test()`
  - `record_equipment_change_for_test()`
- QA 快照会解释 `current_floor` 和 `highest_floor` 的区别，用来定位“为什么打开游戏楼层很高”的体验疑问。
- 修复 `P2LootLoopAcceptanceService` 与 P2 QA 文档中的乱码文本，保留原有阈值和输出结构。

## 验收标准

- 2.5D 可从第 1 层确定性推进到第 5 层，并产生足够的击杀、拾取、装备和成长指标。
- P2 报告可以在测试中达到通过状态。
- 报告能指出失败目标和下一步焦点。
- 不引入新代码生成素材。
- 不清除玩家存档。

## 已验证

- 新增回归先失败，失败原因是缺少 P2 QA 快照和测试钩子。
- 实现后新增回归通过：`NEW_PROJECT_PROTOTYPE_2_5D_P2_LOOT_LOOP_QA_BRIDGE_OK`。
- P2 聚焦测试组通过：`FOCUSED_P2_LOOT_LOOP_QA_OK`。
- 2.5D 聚焦测试组通过：`FOCUSED_PROTOTYPE_2_5D_OK`，共 21 个脚本。
- Godot AI 插件回归通过：`NEW_PROJECT_GODOT_AI_PLUGIN_ENABLED_OK`。
- 全量回归通过：`ALL_NEW_PROJECT_REGRESSION_OK`，共 165 个脚本。
- 主项目 headless 启动通过：退出码 0。
- `git diff --check` 通过。
- 没有残留 headless Godot 测试进程；可见进程为当前项目 Godot 编辑器和 `godot-ai` 服务。

## 仍需人工试玩判断

- 实际 10 分钟手感是否愿意继续刷。
- 背包/装备窗口的信息密度是否能支撑快速判断。
- 敌人动作素材是否足够清楚。
- 清层奖励和 Boss 奖励的视觉反馈是否足够强。
