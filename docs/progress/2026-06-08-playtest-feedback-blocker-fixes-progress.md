# 2026-06-08 试玩反馈阻塞问题修复记录

## 试玩反馈来源

本轮来自真实游玩体验反馈，问题集中在：

- 美术素材与动画可读性不足，敌人攻击/移动/死亡状态难以分辨。
- 背包打开后游戏不暂停，玩家查看装备时会被怪物打死。
- 每次重新游玩时塔层数异常变高。
- HUD 信息不足，缺少清晰的生命、魔力等核心状态。
- 当前素材撕裂感和系统割裂感让体验不像完整游戏。

## 本轮优先处理

### 背包打开暂停战斗

- `Game2D` 打开背包时会暂停场景树。
- 关闭背包后，如果没有暂停菜单保持打开，会恢复战斗。
- 背包窗口设置为 `PROCESS_MODE_ALWAYS`，确保暂停状态下仍可操作 UI。

### HUD 核心战斗信息

- `HudController` 新增：
  - `HealthLabel`
  - `HealthBar`
  - `ManaLabel`
  - `ManaBar`
- `Game2D` 在 HUD 更新时同步 HP/MP。
- 玩家受伤时通过 `health_changed` 立即刷新 HP 显示。

### 回归测试不再污染真实存档

- `SaveManager` 在检测到 `tests/regression` 脚本运行时使用内存临时存档。
- 回归测试仍可读写存档接口，但不会写入真实 `user://dark_tower_2d_save.json`。
- 这解释了“塔层数每次打开都变高”的根因：之前场景回归会实例化 `Game2D` 并触发清层/进下一层保存。

## 新增验证

- `tests/regression/regression_inventory_pauses_combat.gd`
- `tests/regression/regression_hud_vitals_contract.gd`
- `tests/regression/regression_regression_uses_transient_save.gd`

聚焦回归标记：

- `FOCUSED_PLAYTEST_FEEDBACK_FIXES_OK`

## 未在本轮直接解决的问题

### 美术素材割裂和动画不可读

这是当前体验里最大的“游戏感”问题，但不能继续用代码生成形状临时糊上去。后续建议把它作为 P4 前置风险提前处理：

- 建立玩家/敌人动作最低可读标准：idle、run、attack、death 必须能被一眼区分。
- 攻击动画与打击特效分离，素材动画负责身体动作，VFX 负责命中反馈。
- 每个敌人至少要有清楚的攻击前摇和攻击帧，不再接受静态图左右晃动作为攻击表现。
- 正式素材替换继续走 IMAGE2/人工资产管线，不再新增代码生成素材。

## 下一步建议

1. 做一次“试玩体验修复版”人工检查，确认背包暂停、HUD 和层数异常是否已经消失。
2. 把 P4 美术管线任务提前拆出一个 P2/P3 阻塞项：角色/敌人动作可读性最低标准。
3. 在继续扩楼层/Boss 前，先把 HUD、背包和战斗反馈打磨到能支撑真实试玩。
