# 2026-06-07 装备纸娃娃布局进度

## 对应 ROADMAP

- 阶段：P1 可试玩 UI 与装备闭环
- 任务：T-004 装备窗口纸娃娃布局

## 本轮目标

让装备窗口从纯竖排按钮升级为可扩展的角色装备面板。当前先建立结构、槽位摘要和美术锚点，后续可直接接入人物纸娃娃图、装备图标、外观展示、套装效果和职业外观差异。

## 已完成

- `InventoryEquipmentWindow` 新增装备纸娃娃面板：
  - `EquipmentPaperDollPanel`
  - `PaperDollClassLabel`
  - `PaperDollScoreLabel`
  - `PaperDollAnchor`
- 装备面板显示：
  - 当前职业。
  - 总装备评分。
  - 角色美术占位锚点。
  - 武器、护甲、戒指等视觉标签。
- 装备槽按钮继续保留：
  - `EquipmentSlotWeapon`
  - `EquipmentSlotArmor`
  - `EquipmentSlotGloves`
  - `EquipmentSlotRing`
- 新增槽位摘要接口：
  - `get_equipment_slot_summary_for_test(slot)`
  - 返回槽位、装备 ID、名称、是否为空、稀有度、评分、按钮文本和详情提示。

## 回归覆盖

新增：

- `tests/regression/regression_equipment_paper_doll_layout.gd`

已验证：

- `NEW_PROJECT_EQUIPMENT_PAPER_DOLL_LAYOUT_OK`
- `FOCUSED_EQUIPMENT_PAPER_DOLL_REGRESSION_OK`

## ROADMAP 更新

已另存更新版：

- `docs/planning/2026-06-07-dark-tower-2d-arpg-production-roadmap-updated-p1-paper-doll.xlsx`

更新内容：

- T-004 状态改为 `已完成`。
- P1 完成率更新为 `65%`。

## 下一步建议

继续 P1：

- T-005 死亡结算细化。

或补一轮装备窗口视觉 polish：

- 稀有度边框应用到装备槽。
- 纸娃娃锚点接入玩家 IMAGE2 半身/小人预览。
- 装备槽加入图标接口。
