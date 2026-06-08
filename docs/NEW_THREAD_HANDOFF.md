# 新对话接手提示词

下面这段可以直接复制到新的 Codex 对话中使用。

---

你现在接手一个全新的 Godot 4.6.2 纯 2D 暗黑刷宝/爬塔 ARPG 项目。

项目路径：

`H:\GODOT_PROJECT\dark-tower-2d-arpg`

Godot console 路径：

`C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe`

请继续使用 Superpowers 工作流。回答、设计文档、进度文档尽量使用中文。不要清除玩家存档，除非我明确要求。

## 项目方向

这是一个重新开始的干净项目，不再继续修旧的 2.5D/3D 原型。

目标是做成 2D 暗黑刷宝/爬塔 ARPG，优先推进到“可以稳定试玩”的状态。

核心体验：

- 主菜单
- 职业选择
- 主城
- 进入爬塔战斗
- 2D 移动
- 左键攻击
- 击杀敌人
- 掉落拾取
- 背包数据记录
- 清怪开传送门
- 进入下一层
- 回城/死亡后保存角色状态

## 当前新项目已完成

已创建新项目：

- `project.godot`
- `scenes/MainMenu.tscn`
- `scenes/CharacterSelect.tscn`
- `scenes/Town.tscn`
- `scenes/Game2D.tscn`

已创建核心脚本：

- `scripts/app/MainMenu.gd`
- `scripts/app/CharacterSelect.gd`
- `scripts/app/Town.gd`
- `scripts/app/Game2D.gd`
- `scripts/app/SceneRouter.gd`
- `scripts/app/GameConstants.gd`
- `scripts/combat/Player2D.gd`
- `scripts/combat/Enemy2D.gd`
- `scripts/combat/DropItem2D.gd`
- `scripts/combat/Skill2DLibrary.gd`
- `scripts/combat/Vfx2DFactory.gd`
- `scripts/ui/HudController.gd`
- `scripts/save/SaveSchema.gd`
- `scripts/save/SaveManager.gd`
- `scripts/data/PlayerDataService.gd`
- `scripts/data/InventoryDataService.gd`
- `scripts/data/EquipmentDataService.gd`
- `scripts/data/TowerProgressService.gd`
- `scripts/rules/ClassRules.gd`
- `scripts/rules/SkillRules.gd`
- `scripts/rules/EquipmentAffixRules.gd`
- `scripts/rules/LootRules.gd`

已创建回归测试：

- `tests/regression/regression_character_create.gd`
- `tests/regression/regression_enemy_death_once.gd`
- `tests/regression/regression_equipment_can_equip.gd`
- `tests/regression/regression_floor_clear_portal.gd`
- `tests/regression/regression_game2d_input_contract.gd`
- `tests/regression/regression_pickup_inventory_bridge.gd`
- `tests/regression/regression_scene_boot.gd`

已整理文档：

- `docs/NEW_THREAD_HANDOFF.md`
- `docs/design/2026-06-04-design-compendium.md`
- `docs/content/2026-06-04-content-production-brief.md`
- `docs/progress/2026-06-04-new-project-first-playable-progress.md`
- `docs/superpowers/plans/2026-06-04-new-project-first-playable.md`

## 当前验证结果

最近一次完整回归通过：

- `NEW_PROJECT_CHARACTER_CREATE_OK`
- `NEW_PROJECT_ENEMY_DEATH_ONCE_OK`
- `NEW_PROJECT_EQUIPMENT_CAN_EQUIP_OK`
- `NEW_PROJECT_FLOOR_CLEAR_PORTAL_OK`
- `NEW_PROJECT_GAME2D_INPUT_CONTRACT_OK`
- `NEW_PROJECT_PICKUP_INVENTORY_BRIDGE_OK`
- `NEW_PROJECT_SCENE_BOOT_ALL_OK`
- `ALL_NEW_PROJECT_REGRESSION_OK`

主项目 headless 启动退出码为 `0`，没有残留 Godot 测试进程。

## 常用验证命令

完整回归：

```powershell
$godot = 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe'
$project = 'H:\GODOT_PROJECT\dark-tower-2d-arpg'
$tests = Get-ChildItem -Path "$project\tests\regression" -File -Filter '*.gd' | Sort-Object Name | ForEach-Object { 'res://tests/regression/' + $_.Name }
foreach ($test in $tests) {
  Write-Host "RUN $test"
  & $godot --headless --path $project --script $test
  if ($LASTEXITCODE -ne 0) {
    Write-Host "FAILED $test EXIT $LASTEXITCODE"
    exit $LASTEXITCODE
  }
}
Write-Host 'ALL_NEW_PROJECT_REGRESSION_OK'
```

场景烟测：

```powershell
& 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'H:\GODOT_PROJECT\dark-tower-2d-arpg' --script 'res://tests/regression/regression_scene_boot.gd'
```

主入口启动烟测：

```powershell
& 'C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'H:\GODOT_PROJECT\dark-tower-2d-arpg' --quit-after 5
```

检查残留 Godot 进程：

```powershell
Get-Process | Where-Object { $_.ProcessName -like 'Godot_v4.6.2-stable_win64*' } | Select-Object Id,ProcessName
```

## 下一步推荐路线

优先做“第一版可稳定试玩 UI 与稳定性增强”，不要先做大而散的系统。

推荐顺序：

1. 角色选择/存档槽 UI。
2. 紧凑图标网格背包窗口。
3. 装备窗口与装备穿脱交互。
4. 战斗内暂停、回城、死亡结算。
5. 连续楼层稳定性与卡死防护测试。
6. 增加 3 到 5 个楼层节奏变化。
7. 增加敌人类型、精英怪、Boss 雏形。
8. 再扩展职业技能树、主动技能栏、装备词条和符石。

## 重要设计偏好

- 传统 ARPG/MMORPG 角色选择/存档流程。
- 基础职业先行，等级后转职。
- 属性设计不要做成“一个好一个坏”，不同职业拿不同属性应有合理收益。
- 大职业之间装备不互通，同大职业分支之间可共享。
- 装备词条要有适配性，例如投射物 +1 不应出现在战士刀剑上。
- 符石改成直接增加基础属性，BD 由装备词条和技能分支决定。
- 不给装备硬标“适合流派”，让玩家自己研发 BD。
- 背包、仓库、商人、铁匠应是成熟 ARPG/MMORPG 独立窗口，类似魔兽式紧凑图标网格。
- UI 要做分辨率适配，避免 HUD、背包位置偏移、格子溢出。
- 视觉和特效后续优先使用成熟素材；没有素材时可以用程序化特效推进原型。

## 工作注意

- 不要回到旧项目修 3D 场景。
- 不要恢复 POLYGON 资源。
- 不要清除玩家存档，除非我明确要求。
- 每轮重要改动后跑相关测试、完整回归和场景烟测。
- 文档和进度记录尽量写中文。
