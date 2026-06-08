# 2026-06-09 塔前准备建议项进度

## 本轮目标

继续按 ROADMAP 推进 P2 的稳定可试玩体验。本轮在主城塔前准备面板里加入“建议事项”，让玩家在进塔前知道最应该处理什么。

本轮不生成代码素材，不清除玩家存档。

## 已完成

- 新增 `TownPrepRecommendationService`。
- 服务输出：
  - `has_action`
  - `items`
  - `recommendation_text`
- 当前建议项覆盖：
  - 有未使用技能点：提示 `Spend SP N before climbing.`
  - 背包中有可装备升级：提示 `Equip upgrade`
  - 背包物品数量较高：提示 `Bag pressure`
- `TownPrepSummaryService` 接入建议项服务，输出：
  - `recommendations`
  - `recommendation_text`
- 主城准备面板新增 `TownPrepRecommendations`。
- 主城按钮下移，为建议文本留出空间。

## 新增验证

- `tests/regression/regression_town_prep_recommendation_service.gd`
- 扩展 `tests/regression/regression_town_prep_panel_contract.gd`

## 已通过的聚焦验证

- `NEW_PROJECT_TOWN_PREP_RECOMMENDATION_SERVICE_OK`
- `NEW_PROJECT_TOWN_PREP_SUMMARY_SERVICE_OK`
- `NEW_PROJECT_TOWN_PREP_PANEL_CONTRACT_OK`
- `NEW_PROJECT_TOWN_TOWER_START_OPTIONS_OK`
- `TOWN_PREP_RECOMMENDATION_FOCUSED_OK`
- `TOWN_PREP_RECOMMENDATION_RELATED_REGRESSION_OK`
- `ALL_NEW_PROJECT_REGRESSION_OK COUNT 101`
- `HEADLESS_BOOT_EXIT 0`
- `NO_RESIDUAL_GODOT_PROCESS`

## 为后续保留的接口

- 后续可以继续在 `TownPrepRecommendationService` 中加入：
  - 推荐起始层。
  - 推荐战力门槛。
  - 可升级装备名称与评分差。
  - 背包空间上限。
  - 当前职业技能构筑建议。
- 正式 UI 可以直接读取 `items`，做成图标列表、任务条、红点提醒或按钮跳转。
- 该服务不依赖具体主城控件，后续也可以复用到暂停菜单、角色选择页或调试 QA 面板。

## 后续推荐

1. 给建议项增加跳转行为：点击“Spend SP”打开技能区域，点击“Equip upgrade”打开背包装备筛选。
2. 把准备面板视觉化为暗黑刷宝风格界面，减少普通控件感。
3. 为背包容量建立明确规则，这样 `Bag pressure` 能从软提示变成真实系统。
