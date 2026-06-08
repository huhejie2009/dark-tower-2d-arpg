# 2026-06-09 主城塔前准备面板进度

## 本轮目标

继续按 ROADMAP 推进 P2 的稳定可试玩体验。本轮把主城从临时按钮入口推进到“塔前准备界面”的第一版，让玩家在进塔前能看到角色状态、进度、资源、成长和起始层选择。

本轮不生成代码素材，不清除玩家存档。

## 设计取向

采用保守实现：

- 不重做主城美术。
- 不引入代码生成素材。
- 不把 UI 显示逻辑直接散落在主城脚本里。
- 先建立结构化摘要服务，后续正式 UI、美术背景、章节选择、难度选择都复用这份数据。

## 已完成

- 新增 `TownPrepSummaryService`。
- `TownPrepSummaryService.build_summary(player_data)` 输出：
  - `character_text`
  - `progress_text`
  - `resource_text`
  - `growth_text`
  - `start_text`
  - `gear_score`
  - `gold`
  - `crystal`
  - `inventory_items`
  - `start_options`
- 主城新增 `TownPrepPanel`。
- 准备面板现在显示：
  - `TownCharacterSummary`：角色名、职业、等级。
  - `TownProgressSummary`：历史最高层、装备评分。
  - `TownResourceSummary`：金币、晶体、背包物品数量。
  - `TownGrowthSummary`：技能点、伤害、生命、魔力。
  - `TownStartSummary`：从 1 层开始或挑战最高层的说明。
- 主城仍保留：
  - `EnterTowerButton`
  - `EnterBestFloorButton`
  - `OpenInventoryButton`
  - `ReturnMainMenuButton`

## 新增验证

- `tests/regression/regression_town_prep_summary_service.gd`
- `tests/regression/regression_town_prep_panel_contract.gd`

## 已通过的聚焦验证

- `NEW_PROJECT_TOWN_PREP_SUMMARY_SERVICE_OK`
- `NEW_PROJECT_TOWN_PREP_PANEL_CONTRACT_OK`
- `NEW_PROJECT_TOWN_TOWER_START_OPTIONS_OK`
- `TOWN_PREP_PANEL_FOCUSED_OK`
- `TOWN_PREP_RELATED_REGRESSION_OK`
- `ALL_NEW_PROJECT_REGRESSION_OK COUNT 100`
- `HEADLESS_BOOT_EXIT 0`
- `NO_RESIDUAL_GODOT_PROCESS`

## 为后续保留的接口

- 后续正式主城 UI 可以直接读取 `TownPrepSummaryService.build_summary()`，不用再到处读 `player_data`。
- 后续“塔前准备界面”可以继续扩展：
  - 起始层推荐战力。
  - 本次爬塔目标。
  - 章节/难度选择。
  - 赛季或挑战词缀。
  - 装备与技能升级提醒。
- 如果后续接入正式背景图或手绘 UI，只需要替换显示层，不需要改主城核心数据流。

## 后续推荐

1. 把主城准备面板视觉化为更正式的暗黑刷宝 UI，使用真实/IMAGE2 背景素材而不是继续堆普通控件。
2. 给塔前准备面板增加“建议处理事项”：可用技能点、可装备升级、背包空间、推荐起始层。
3. 在战斗 HUD 中区分“本次层数”和“历史最高层”，让爬塔目标更清晰。
