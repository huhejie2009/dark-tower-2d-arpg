# Dark Tower 2D ARPG

Godot 4.6.2 纯 2D 暗黑刷宝 / 爬塔 ARPG 新项目。

项目目标是先做出稳定可试玩的 2D 刷宝闭环，再逐步补齐正式美术、动作素材、楼层内容、装备成长、技能成长和长期可维护的制作管线。

## 当前状态

当前版本已经具备第一版可试玩闭环：

- 主菜单
- 职业选择
- 主城与塔前准备面板
- 存档槽与基础玩家数据
- 2D 战斗场景
- WASD / 方向键移动
- 左键基础攻击
- 敌人追击、攻击、死亡
- 掉落拾取进入背包
- 背包、装备、装备评分、装备推荐、装备对比摘要与对比原因
- 交付级物品实例契约：`instance_id`、`item_power`、`binding_flags`、`icon_id`、`source_tags`
- 背包查询服务：装备、材料、升级、锁定、收藏、废品筛选与排序接口
- 背包窗口高级筛选：升级、锁定、收藏、废品
- 物品锁定、收藏、废品标记写入 `binding_flags`
- 技能点与基础技能成长
- 战斗内暂停、背包暂停、死亡结算
- 清怪开门 / 传送门进入下一层
- 从第 1 层开始或挑战历史最高层
- HUD 显示生命、魔力、经验、技能点、掉落提示
- Godot AI 与 godot-devtool MCP 插件接入
- 回归测试与场景启动烟测

## 项目路径

```text
H:\GODOT_PROJECT\dark-tower-2d-arpg
```

Godot 项目入口：

```text
H:\GODOT_PROJECT\dark-tower-2d-arpg\project.godot
```

推荐 Godot 版本：

```text
Godot 4.6.2 stable
```

当前机器常用 Godot console：

```text
C:\Users\huhej\.codex\mcp\godot-bin\Godot_v4.6.2-stable_win64_console.exe
```

## 目录说明

- `scenes/`：Godot 场景入口。
- `scripts/`：游戏逻辑、数据服务、规则、UI、战斗脚本。
- `tests/regression/`：回归测试脚本。
- `assets/`：当前接入的临时 / IMAGE2 / 预览素材。
- `addons/`：Godot 插件，包括 Godot AI 与 godot-devtool。
- `docs/design/`：世界观、美术、视角、系统设计文档。
- `docs/progress/`：每轮开发进度记录。
- `docs/planning/`：ROADMAP 表格与可视化路线图。
- `docs/qa/`：试玩与验收标准。
- `docs/NEW_THREAD_HANDOFF.md`：新线程接手时优先阅读的总入口。

## 重要约束

- 不要清除玩家存档，除非用户明确要求。
- 本项目是 2D 主线，不回到旧 3D / POLYGON 项目。
- 后续素材管线优先使用正式美术、IMAGE2 或人工资产，不继续堆代码生成素材。
- 打击特效与角色 / 敌人动作动画分离。
- 游戏内视角已经转向俯视 2D 制作标准，方便素材制作和碰撞体积控制。

## 推荐阅读顺序

新线程或新开发者接手时，先读：

1. `docs/NEW_THREAD_HANDOFF.md`
2. `docs/design/2026-06-04-design-compendium.md`
3. `docs/content/2026-06-04-content-production-brief.md`
4. `docs/progress/2026-06-04-new-project-first-playable-progress.md`
5. `docs/planning/` 下最新 ROADMAP 表格

## 回归测试

PowerShell 示例：

```powershell
$godot = 'C:\Users\huhej\.codex\mcp\godot-bin\Godot_v4.6.2-stable_win64_console.exe'
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

最近验证标记：

- `ALL_NEW_PROJECT_REGRESSION_OK COUNT 121`
- `HEADLESS_BOOT_EXIT 0`
- `NO_RESIDUAL_HEADLESS_TEST_GODOT_PROCESS`

Godot 退出时可能出现 `ObjectDB instances leaked` / `resources still in use` 警告；目前只要退出码为 0 且完整回归通过，就按非阻断清理项处理。

## 下一步方向

短期优先级：

1. 基于 `binding_flags` 完成废品批量出售/分解前置数据服务。
2. 为仓库、商人、铁匠窗口复用 `InventoryQueryService` 做接口准备。
3. 继续完善 HUD、背包、装备、技能与死亡结算体验。
4. 准备正式 2D 人物、敌人、动作和环境素材替换。
5. 扩展 3 到 5 个楼层节奏变化，并增加更稳定的连续楼层测试。

## 2026-06-10 更新：废品批量处理前置

- 新增 `InventoryItemActionService`，集中处理背包物品操作规则。
- 新增废品批量出售/分解预览与执行接口，后续商人和铁匠窗口可直接复用。
- 锁定、收藏、已装备、不可出售物品会被自动保护，不会被批量处理。
- 背包窗口新增 `SellJunkButton` 与 `SalvageJunkButton`，先以文字按钮保留正式图标素材接口。
- 新增回归：`regression_inventory_junk_batch_actions.gd`。

## 2026-06-10 更新：废品处理确认弹窗

- 背包窗口新增 `JunkActionConfirmDialog`。
- `Sell Junk` / `Salvage` 会先显示处理数量、保护数量和预计收益，确认后才执行。
- 新增待确认预览接口，后续商人和铁匠可以复用同一套确认流程。
- 新增回归：`regression_inventory_junk_action_confirmation.gd`。

## 2026-06-11 更新：主城可走动空间 V1

- 主城新增 `TownWorldRoot` 世界层和 `TownPlayer` 可移动玩家。
- 新增通天塔入口、商人、铁匠、仓库、训练五个交互点占位。
- 主城支持 WASD / 方向键移动，靠近交互点可按 `E` 触发。
- 商人、铁匠、仓库当前先复用已有背包窗口，后续可替换为独立窗口。
- 新增回归：`regression_town_playable_space_contract.gd`。

## 2026-06-11 更新：主城截图 QA 与布局修复

- 通过 `tools/qa_capture_town_screenshot.gd` 导出 1280x720 主城截图，确认 V1 主城整备面板遮挡可玩空间的问题。
- 主城调整为左侧可行走世界、右侧整备栏，玩家、通天塔入口、商人、铁匠、仓库、训练点均保持在可见可玩区域内。
- 右侧按钮组重新排版，`Main Menu` 在 720p 下不再出屏。
- 互动提示移动到屏幕内，保留后续商人、铁匠、仓库独立窗口的接口位置。
- 新增回归：`regression_town_playable_space_visual_layout.gd`。
- 截图验收文件：`docs/qa/screenshots/town_playable_space_1280x720.png`。

## 2026-06-11 更新：主城设施窗口 V1

- 新增 `TownFacilityService`，集中维护商人、铁匠、仓库、训练设施配置。
- 新增 `TownFacilityWindow`，主城设施交互先打开独立设施窗口，再桥接背包、装备、卖废品、分解废品或技能页。
- 商人、铁匠、仓库、训练不再直接强行打开背包窗口，为后续正式商店、仓库、铁匠系统预留接口。
- 新增截图验收：`docs/qa/screenshots/town_merchant_facility_1280x720.png`。
- 新增回归：`regression_town_facility_service_contract.gd`、`regression_town_facility_window_contract.gd`。

## 2026-06-11 更新：仓库数据服务 V1

- 新增 `StashStorageService`，支持背包与仓库之间整件/整栈存取。
- 仓库默认 80 格，容量摘要复用背包容量规则。
- 已装备物品不能直接存入仓库，背包满时不能从仓库取出，失败操作不改变数据。
- `SaveSchema` 规范化 `stash` 字段，为旧存档和后续仓库窗口做兼容保护。
- 新增回归：`regression_stash_storage_rules.gd`。

## 2026-06-11 更新：仓库窗口 V1

- 新增 `StashWindow`，主城仓库设施可以打开独立仓库窗口。
- 仓库窗口支持背包与仓库之间整件/整栈存取，并保存玩家背包和当前存档槽仓库数据。
- 打开仓库时会关闭设施面板，避免窗口互相遮挡。
- 新增截图验收：`docs/qa/screenshots/town_stash_window_1280x720.png`。
- 新增回归：`regression_stash_window_contract.gd`。

## 2026-06-11 更新：商人交易数据服务 V1

- 新增 `VendorTransactionService`，先做商人系统数据底座，不继续打磨占位 UI。
- 支持单件卖出、买回池、买回恢复。
- 锁定、收藏、不可出售、已装备物品会被保护，不能误卖。
- V1 买回价等于卖出价，优先保证误卖恢复；后续经济系统再统一调数值。
- 新增回归：`regression_vendor_transaction_rules.gd`。

## License

未定。正式发布或对外协作前需要补充许可说明。
