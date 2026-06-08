# 2026-06-05 玩家死亡表现窗口进度

## 目标

玩家死亡后不要立刻弹出结算面板，而是先留出一小段死亡表现窗口，让当前程序化角色和后续 IMAGE2 `death` 动画都有时间展示，再进入已有死亡结算。

## 已完成

- `Game2D.gd` 新增死亡表现等待状态 `death_presentation_pending`。
- 玩家死亡后现在会：
  - 立即进入死亡结算流程锁定状态，阻止继续攻击、移动、开背包或进传送门。
  - 立即保存当前玩家数据，并把回城生命值写成半血。
  - 清空玩家移动输入，避免死亡表现期间继续滑动。
  - 等待短暂死亡表现窗口后，再显示现有 `DeathSettlementOverlay`。
- 保留现有死亡结算面板、分区文本、回城按钮和焦点逻辑。
- 新增测试接口：
  - `_set_death_presentation_delay_for_test(delay)`
  - `_is_death_presentation_pending_for_test()`
- 新增回归测试 `regression_player_death_presentation_delay.gd`。
- 更新旧的 `regression_death_settlement_contract.gd`，使其匹配新的“先表现、后结算”节奏。

## 验证结果

- 单项回归：
  - `NEW_PROJECT_PLAYER_DEATH_PRESENTATION_DELAY_OK`
  - `NEW_PROJECT_DEATH_SETTLEMENT_CONTRACT_OK`
- 完整回归：`ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动：`HEADLESS_EXIT 0`
- 已检查并清理本轮遗留的 headless 测试进程，最终无 Godot 残留进程输出。

## 未触碰范围

- 没有清除玩家存档。
- 没有修改存档结构。
- 没有回到旧 3D 项目。
- 没有恢复 POLYGON 资源。
- 没有导入正式 IMAGE2 角色图片，只继续保留并使用后续 SpriteSheet 动画接口。

## 当前限制

- 死亡表现窗口目前使用默认短延迟，尚未按玩家 manifest 中 `death` 动画帧数和 fps 动态计算。
- 玩家死亡表现期间敌人仍可继续运行，但战斗输入和菜单入口已被锁住；后续可按需要冻结敌人或加入镜头/慢动作效果。

## 下一步建议

1. 让玩家死亡表现窗口优先读取 IMAGE2 `death` 动画时长。
2. 接入第一套 IMAGE2 玩家 SpriteSheet，实机验证 idle/run/attack/death。
3. 给死亡结算增加更明确的视觉层级、按钮状态和音效反馈。
