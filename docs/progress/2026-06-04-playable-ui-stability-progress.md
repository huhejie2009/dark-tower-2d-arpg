# 2026-06-04 第一版可试玩 UI 与稳定性增强进度

## 本轮目标

在不清除玩家存档、不回到旧 3D 项目的前提下，把新 2D 暗黑刷宝/爬塔 ARPG 从最小战斗闭环推进到更接近可试玩原型：

1. 角色选择支持 3 个存档槽。
2. 主城与战斗内提供第一版背包/装备窗口。
3. 装备支持穿戴、卸下与属性汇总。
4. 战斗内提供暂停菜单与回城入口。
5. 给回城、死亡等切场景行为加防重复触发保护。

## 已完成内容

### 角色/存档槽 UI

- `CharacterSelect.gd` 改为显示 `slot_1`、`slot_2`、`slot_3` 三个角色槽。
- 已有角色槽点击后会设置为当前激活槽并进入主城。
- 空槽可以先选择职业，再点击创建按钮写入选中的空槽。
- 新增 `SaveManager.set_active_slot_in_data()` 与 `SaveManager.set_active_slot()`，用于测试与实际 UI 切换。

### 背包与装备窗口

- 新增 `scripts/ui/InventoryEquipmentWindow.gd`。
- 主城新增 `OpenInventoryButton`，可打开背包/装备窗口。
- 战斗内可按 `I` 或 `C` 打开同一套窗口。
- 窗口包含：
  - 固定尺寸图标网格背包。
  - 装备槽列表。
  - 基础属性汇总。
  - 鼠标悬停说明与点击详情。
- 点击背包装备会尝试穿戴。
- 点击已装备槽位会卸下，但不会删除背包物品。

### 战斗暂停与稳定性

- `Game2D.gd` 新增 `PauseOverlay`。
- 战斗内按 `Esc` 打开/关闭暂停菜单。
- 暂停菜单提供继续、背包/装备、回城按钮。
- 回城与死亡回城新增 `transition_locked`，防止同一轮切场景重复触发。
- 进入下一层新增 `floor_transition_locked`，防止传送门或快速按键重复切层。

## 新增回归测试

- `regression_save_slots_ui_contract.gd`
  - 验证 3 槽 UI 合约。
  - 验证激活槽数据切换。
- `regression_equipment_unequip_and_stats.gd`
  - 验证装备卸下。
  - 验证卸下后属性汇总回落。
- `regression_game2d_pause_contract.gd`
  - 验证暂停层、回城按钮与切场景锁存在。

## 本轮验证结果

已使用 Godot 4.6.2 headless 验证：

- `NEW_PROJECT_SAVE_SLOTS_UI_CONTRACT_OK`
- `NEW_PROJECT_EQUIPMENT_UNEQUIP_AND_STATS_OK`
- `NEW_PROJECT_GAME2D_PAUSE_CONTRACT_OK`
- `ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动退出码：`0`
- 残留 Godot 测试进程：未发现

## 当前限制

- UI 文案暂时偏功能原型，视觉还不是最终暗黑风格。
- 背包格子已有紧凑网格，但还没有排序、筛选、锁定图标状态。
- 装备详情已有基础说明，但还没有做新旧装备对比高亮。
- 暂停使用的是菜单层，后续还需要更完整的死亡结算界面。

## 下一步建议

1. 给背包加入排序、锁定与基础筛选。
2. 给装备详情加入新旧装备属性对比。
3. 做死亡结算弹窗：保留当前楼层、奖励、回城按钮。
4. 增加连续 10 层稳定性回归，覆盖快速按 `E` 与清层后切层。
5. 加入 3 到 5 个楼层节奏模板，开始拉开爬塔体验差异。
