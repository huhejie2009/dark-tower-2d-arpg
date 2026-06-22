# 中文化与宝石刷宝闭环进度

日期：2026-06-14

## 本轮目标

让游侠寒冰射击 CoC 从后台规则推进为玩家可理解、可刷取、可操作的第一版 Build 闭环。

## 已完成

### 全局中文化

- 中文化主菜单、职业选择、主城、战斗 HUD、背包、装备、天赋和死亡结算。
- 中文化装备推荐、装备操作提示、掉落通知和塔层准备信息。
- 修复职业、技能、敌人、装备与词条名称中的乱码。
- 同步更新相关回归测试的中文断言。

### 宝石获取

- `LootQualityService` 在每第 7 个击杀生成宝石类型掉落。
- `GemSocketService` 负责按职业、楼层和击杀序号选择宝石。
- 游侠宝石成长节奏：
  - 初期：寒霜、精准、迅捷。
  - 第 4 层起：穿透。
  - 第 7 层起：分裂。
- 非游侠职业暂时使用精准和迅捷通用池，后续按职业扩展。

### 宝石表现

- 宝石掉落使用冰蓝色晶体。
- HUD 显示“获得宝石”通知。
- 背包保留 `gem_id`，确保堆叠物品仍能识别具体宝石。
- 材料筛选包含宝石。

### 宝石镶嵌

- 装备详情显示宝石孔使用情况。
- 装备详情显示已镶嵌宝石名称和当前可镶嵌宝石。
- 选中已装备物品时，操作按钮可切换为“镶嵌”。
- 镶嵌成功后：
  - 宝石写入装备 `socketed_gems`。
  - 背包宝石数量减少。
  - 装备评分和角色总属性立即更新。

## 架构职责

- `GemSocketService`：宝石定义、掉落选择、孔位规则、镶嵌/取下和属性聚合。
- `LootQualityService`：决定一次击杀产生的掉落类型。
- `LootRules`：组装正式掉落物品数据。
- `InventoryDataService`：保存宝石物品身份。
- `LootNotificationService`：构建玩家可见的拾取反馈。
- `InventoryEquipmentWindow`：展示孔位并发起镶嵌操作。
- `EquipmentDataService`：聚合宝石提供的战斗属性和装备评分。

## 验证

已通过：

- `NEW_PROJECT_GEM_LOOT_RULES_OK`
- `NEW_PROJECT_GEM_SOCKET_SERVICE_OK`
- `NEW_PROJECT_INVENTORY_GEM_SOCKET_UI_OK`
- `NEW_PROJECT_RANGER_COC_EQUIPMENT_STATS_OK`
- `NEW_PROJECT_RANGER_COC_COMPARE_REASONS_OK`
- `NEW_PROJECT_LOOT_QUALITY_RULES_OK`
- `NEW_PROJECT_LOOT_NOTIFICATION_SERVICE_OK`
- `NEW_PROJECT_PICKUP_INVENTORY_BRIDGE_OK`
- `NEW_PROJECT_GAME2D_LOOT_NOTIFICATION_BRIDGE_OK`
- `NEW_PROJECT_INVENTORY_QUERY_SERVICE_OK`
- `NEW_PROJECT_SCENE_BOOT_ALL_OK`

## 下一步

1. 让冰矛穿透与分裂属性真正改变弹道行为。
2. 增加宝石选择、替换和取下界面，而不是只自动选择第一颗可用宝石。
3. 为不同职业建立独立宝石池和技能联动。
4. 增加自动拾取过滤与挂机构筑摘要。
5. 进行 10 分钟游侠挂机刷宝试玩，调整宝石掉率和 Build 成长速度。
