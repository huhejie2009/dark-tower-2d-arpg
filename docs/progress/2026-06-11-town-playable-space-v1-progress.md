# 主城可走动空间 V1 进度

日期：2026-06-11  
路线图对应：P2 稳定可试玩体验，P3 商人/铁匠/仓库入口前置

## 本轮目标

把主城从“功能按钮和准备面板”推进为“可走动的塔前据点 1.0”。本轮不制作正式素材，不生成图片素材，只做可替换的空间 blockout、玩家移动和交互点承载层。

## 本轮完成

- `Town.tscn` 保持现有入口不变，继续使用 `scripts/app/Town.gd`。
- `Town.gd` 新增 `TownWorldRoot`，作为主城世界层。
- 新增可移动玩家节点 `TownPlayer`。
- 新增主城交互点：
  - `TownTowerGateInteraction`：通天塔入口。
  - `TownMerchantInteraction`：商人占位。
  - `TownBlacksmithInteraction`：铁匠占位。
  - `TownStashInteraction`：仓库占位。
  - `TownTrainingInteraction`：训练/技能占位。
- 新增 `TownInteractionHint`，靠近交互点时提示按 `E`。
- 主城支持 WASD / 方向键移动。
- `E` 键可触发最近交互点。
- 商人、铁匠、仓库占位当前先路由到已有背包窗口。
- 训练点当前路由到已有技能节点入口。
- 通天塔入口当前路由到从 1 层开始进入塔。

## 保留内容

- 原有 `TownPrepPanel` 继续保留。
- 原有 `EnterTowerButton`、`EnterBestFloorButton`、`OpenInventoryButton`、`ReturnMainMenuButton` 继续保留。
- 已有背包、装备、技能、废品确认流程不重写，只接入主城交互点。

## 新增测试

- `tests/regression/regression_town_playable_space_contract.gd`

## 验证结果

目标回归已通过：

- `NEW_PROJECT_TOWN_PLAYABLE_SPACE_CONTRACT_OK`
- `NEW_PROJECT_TOWN_PREP_PANEL_CONTRACT_OK`
- `NEW_PROJECT_TOWN_PREP_ACTION_BUTTON_OK`
- `NEW_PROJECT_TOWN_TOWER_START_OPTIONS_OK`
- `NEW_PROJECT_DARK_ARPG_UI_THEME_CONTRACT_OK`
- `NEW_PROJECT_SCENE_BOOT_ALL_OK`
- `FOCUSED_TOWN_PLAYABLE_SPACE_OK`

Godot headless 退出时仍有已知的 `ObjectDB instances leaked` / `resources still in use` 清理警告；目标测试退出码为 0，按非阻断处理。

## 后续建议

1. 把商人、铁匠、仓库从“占位交互点”升级为独立窗口。
2. 给主城做正式视觉设计：塔前营地、冷峻平原、通天塔入口、功能 NPC 区域。
3. 做主城实机截图 QA，检查面板遮挡、交互提示位置和玩家动线。
4. 后续替换正式素材时保留 `TownWorldRoot`、交互点 id 和测试接口，避免破坏系统入口。
