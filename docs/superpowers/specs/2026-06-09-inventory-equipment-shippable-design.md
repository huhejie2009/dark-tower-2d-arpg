# Superpowers 规格：背包与装备系统交付级设计

本规格已按项目文档位置落地，详见：

- `docs/design/2026-06-09-inventory-equipment-shippable-system-design.md`
- `docs/planning/2026-06-09-inventory-equipment-shippable-roadmap.md`

核心结论：

- P2 先完成数据稳定、背包装备窗口、穿脱交互、暂停保护、对比摘要和 10 到 30 分钟试玩验收。
- P3 再做仓库、商人、铁匠和材料仓库。
- P4 再做掉落过滤与构筑目标。
- 所有变更必须保护旧存档，不清除玩家数据。
- 美术资源通过 `icon_id` 等接口替换，不把代码生成素材当作最终资产。

