# 2026-06-09 装备操作提示与 Godot Devtool Skills 检查进度

## 本轮目标

继续按 ROADMAP 推进 P2 的背包、装备、刷宝可读性体验。本轮优先解决试玩反馈中的一个核心问题：打开背包后，玩家不能快速判断一件装备能不能穿、值不值得穿、为什么不能穿。

本轮不生成代码素材，不清除玩家存档。

## 已完成

- 新增 `EquipmentActionHintService`。
- 背包装备详情增加 `Action` 段落，直接显示：
  - 当前物品是否可装备。
  - 换装评分增减。
  - 是否职业不匹配。
  - 是否已经装备。
  - 是否只是横向替换或降级替换。
- 背包右侧的装备按钮现在使用同一份操作提示数据：
  - 可提升装备显示 `Equip +N`。
  - 降级但可穿的装备显示 `Equip -N`。
  - 职业不匹配显示 `Class blocked` 并禁用按钮。
  - 已装备物品显示 `Equipped` 并禁用按钮。
- `InventoryEquipmentWindow` 增加测试接口 `get_item_action_hint_for_test(item_id)`，后续正式装备卡、悬浮提示、手柄/键鼠快捷操作可以复用。

## Godot Devtool / Skills 检查

- Godot MCP 能力检查通过：
  - Godot 版本：`4.6.2.stable.official.71f334935`
  - `godot-devtool` 版本：`3.2.0`
  - MCP server 模式：`mcp_stdio`
  - bridge 模式：`websocket`
  - 总工具数：`235`
  - runtime test 工作流工具数：`14`
  - `GODOT_PATH` 已配置
- 已把构建产物里的 6 个 Godot Devtool Skills 同步到 Codex Skills 目录：
  - `godot-devtool`
  - `godot-devtool-live-editor`
  - `godot-devtool-project-setup`
  - `godot-devtool-release-verify`
  - `godot-devtool-runtime-test`
  - `godot-devtool-scene-authoring`
- 当前会话已经能调用 `godot-devtool` MCP 工具；新同步的 Skills 可能需要 Codex 后续会话刷新后才会显示在技能清单里。

## 新增验证

- `tests/regression/regression_equipment_action_hint_service.gd`
- `tests/regression/regression_inventory_equipment_action_hints.gd`

## 已通过的聚焦回归

- `NEW_PROJECT_EQUIPMENT_ACTION_HINT_SERVICE_OK`
- `NEW_PROJECT_INVENTORY_EQUIPMENT_ACTION_HINTS_OK`
- `NEW_PROJECT_EQUIPMENT_COMPARE_SUMMARY_SERVICE_OK`
- `NEW_PROJECT_INVENTORY_RECOMMENDATION_TAGS_OK`
- `NEW_PROJECT_INVENTORY_EQUIPMENT_SELECTION_ACTIONS_OK`
- `NEW_PROJECT_EQUIPMENT_CAN_EQUIP_OK`
- `EQUIPMENT_ACTION_HINT_RELATED_REGRESSION_OK`

## 为后续保留的接口

- 正式装备卡 UI 可以读取 `button_text`、`primary_text`、`detail_text`、`score_delta`、`reason`，不需要重新解析详情文本。
- 后续的战斗内暂停背包、商店、铁匠、仓库、掉落悬浮提示都可以复用 `EquipmentActionHintService.build_hint()`。
- 等 IMAGE2 或人工素材接入后，装备图标角标可以直接使用 `upgrade`、`can_equip`、`reason` 做视觉提示，不需要改底层装备服务。

## 后续推荐

1. 把背包打开时的暂停/安全状态与死亡结算流程进一步打通，避免玩家查看装备时被怪物击杀。
2. 做正式 HUD 信息层，补齐血量、魔力、经验、楼层、金币/材料、当前目标。
3. 在不生成代码素材的前提下，继续预留素材 manifest 和动画状态接口，等待正式 2D 人物、敌人、动作素材替换。
