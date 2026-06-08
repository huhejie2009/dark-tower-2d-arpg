# 2026-06-04 可试玩 UI 与稳定性增强续进度

## 本轮目标

继续推进上一轮“第一版可稳定试玩 UI 与稳定性增强”，重点补齐：

1. 背包排序、筛选与锁定的第一版交互。
2. 装备详情里的新旧装备属性对比。
3. 死亡后不再瞬间回城，而是显示死亡结算窗口。
4. 连续楼层切换稳定性回归。

## 已完成内容

### 背包工具栏

- `InventoryEquipmentWindow.gd` 增加背包工具栏。
- 新增按钮：
  - `SortInventoryButton`
  - `FilterAllButton`
  - `FilterEquipmentButton`
  - `FilterMaterialButton`
- 支持按全部、装备、材料/货币筛选。
- 支持名称/类型两种基础排序模式循环。
- 锁定物品会优先显示，避免排序时被冲散。

### 物品锁定

- `InventoryEquipmentWindow.gd` 新增 `toggle_item_lock(item_id)`。
- 锁定状态写入背包条目。
- 装备物品会同步写入其 `equipment.locked` 字段。
- 锁定不会删除物品，不会改变数量，也不会阻止后续保存。

### 装备对比

- 装备详情新增 `Compare` 段落。
- 对比逻辑基于候选装备槽位查找当前已穿戴装备。
- 显示候选装备相对当前装备的词条变化，例如 `attack_damage +15`。
- 空槽位会显示 `Compare: empty slot`。

### 死亡结算

- `Game2D.gd` 新增 `DeathSettlementOverlay`。
- 玩家死亡后：
  - 显示死亡结算层。
  - 暂停战斗。
  - 保存已经拾取的物品。
  - 将玩家回城后的生命设置为半血。
- 点击 `DeathReturnTownButton` 才真正回主城。
- 死亡结算不会立刻锁住切场景流程，避免 UI 还没显示就被直接跳走。

### 连续楼层稳定性

- 新增连续 10 层回归。
- 覆盖清层、传送门、快速重复进层调用后的楼层数一致性。
- 验证传送门被消费、楼层锁释放。

## 新增回归测试

- `regression_inventory_tools_contract.gd`
- `regression_equipment_compare_text.gd`
- `regression_death_settlement_contract.gd`
- `regression_ten_floor_stability.gd`

## 验证结果

已使用 Godot 4.6.2 headless 验证：

- `NEW_PROJECT_INVENTORY_TOOLS_CONTRACT_OK`
- `NEW_PROJECT_EQUIPMENT_COMPARE_TEXT_OK`
- `NEW_PROJECT_DEATH_SETTLEMENT_CONTRACT_OK`
- `NEW_PROJECT_TEN_FLOOR_STABILITY_OK`
- `ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动退出码：`0`
- 残留 Godot 测试进程：未发现

## 当前限制

- 背包锁定目前有数据行为和排序行为，但还没有独立锁图标。
- 筛选类型仍较少，后续可扩展为装备部位、稀有度、职业池。
- 装备对比是文本型，尚未做颜色高亮。
- 死亡结算已有流程，但还没有展示详细奖励、击杀数、耗时等信息。

## 下一步建议

1. 做 3 到 5 个楼层节奏模板，开始拉开战斗体验。
2. 增加普通敌人的类型差异：近战、远程、高血量守卫。
3. 给死亡结算加入击杀数、拾取列表、楼层奖励。
4. 给背包锁定和筛选按钮补视觉状态。
5. 开始小 Boss 或精英词缀雏形。
