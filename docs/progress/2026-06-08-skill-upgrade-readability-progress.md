# 2026-06-08 技能升级可读性进度

## 本轮目标

继续推进 ROADMAP P2「战斗手感与刷宝驱动」。本轮重点是把基础攻击升级从“按钮可点击”推进到“玩家能看懂为什么要点、点了得到什么、为什么现在不能点”。

本轮不生成代码素材，不清除玩家存档。

## 已完成

- 新增 `SkillUpgradePreviewService`。
- 基础攻击升级预览 payload 包含：
  - `node_id`
  - `title`
  - `current_level`
  - `next_level`
  - `max_level`
  - `skill_points`
  - `skill_point_cost`
  - `damage_gain`
  - `can_upgrade`
  - `reason`
  - `summary_text`
  - `status_text`
  - `tooltip_text`
- `InventoryEquipmentWindow` 接入技能升级预览服务。
- 技能区现在显示：
  - 当前 SP
  - 基础攻击训练当前等级/满级
  - 下一级伤害收益
  - 消耗
  - 可升级或阻塞原因
- 升级按钮现在带 tooltip，后续正式 UI、音效提示、教学浮层可以共用同一份 preview payload。

## 新增验证

- `tests/regression/regression_skill_upgrade_readability.gd`
- 聚焦回归：
  - `FOCUSED_P2_SKILL_UPGRADE_READABILITY_REGRESSION_OK`

## ROADMAP 更新

- 新增版本：
  - `docs/planning/2026-06-08-dark-tower-2d-arpg-production-roadmap-updated-p2-skill-readability.xlsx`
- P2 完成率更新到 68%。
- T-009 更新为「装备推荐、背包与技能升级可读性」。

## 为后续保留的接口

- 未来技能树面板可以直接读取 `SkillUpgradePreviewService`，不需要重新判断技能点、等级、消耗和阻塞原因。
- 未来升级成功弹窗、音效、按钮闪光、教学提示可以使用 `summary_text` / `status_text` / `tooltip_text`。
- 未来如果基础攻击训练扩展成多职业不同收益，可以保留 payload 字段，替换服务内部计算。

## 后续推荐

1. 把装备对比详情继续压缩成“核心差异列表”，减少背包详情文字噪音。
2. 扩展技能升级服务到 2-3 个真实技能节点，但先保持最小技能树，不急着做大系统。
3. 为 P2 增加“10 分钟刷宝目标检查”：掉落、升级、换装是否形成连续动机。
