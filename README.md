# Dark Tower 2D ARPG

Godot 4.6.3 纯 2D 暗黑刷宝 / 爬塔 ARPG 项目。

当前目标是先把游戏做到稳定可试玩：主城准备、进塔战斗、掉落拾取、背包装备、经验成长、死亡结算和返回主城形成闭环；美术资产继续保留正式素材接入接口，避免继续依赖代码生成素材。

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
- 手动 / 挂机战斗模式
- 游侠寒冰射击暴击触发冰矛的 CoC 构筑
- 游侠 CoC 天赋、装备词条和装备作用解释
- 通用宝石孔、宝石属性聚合与背包镶嵌入口
- 宝石刷图掉落、中文通知和独立掉落视觉
- 主菜单、主城、战斗、背包、装备、天赋和结算中文化
- Godot AI 与 godot-devtool MCP 插件接入
- 回归测试与场景启动烟测

## 项目路径

当前工作区由开发者自行选择，不依赖固定盘符。

Godot 项目入口：

项目根目录下的 `project.godot`。

推荐 Godot 版本：

```text
Godot 4.6.3 stable
```

当前机器常用 Godot console：

```text
D:\Godot\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe
```

## 目录说明

- `scenes/`：Godot 场景入口。
- `scripts/`：游戏逻辑、数据服务、规则、UI 和战斗脚本。
- `tests/regression/`：回归测试脚本。
- `assets/`：当前接入的临时 / IMAGE2 / 预览素材。
- `addons/`：Godot 插件，包括 Godot AI 和 godot-devtool。
- `docs/design/`：世界观、美术、视角和系统设计文档。
- `docs/content/`：素材生产、动画规格和内容制作说明。
- `docs/progress/`：每轮开发进度记录。
- `docs/planning/`：ROADMAP、阶段验收和路线图。
- `docs/qa/`：试玩、截图和验收记录。
- `docs/NEW_THREAD_HANDOFF.md`：新线程接手时优先阅读的总入口。

## 重要约束

- 不要清除玩家存档，除非用户明确要求。
- 本项目是新 2D / 2.5D 主线，不回到旧 3D / POLYGON 项目。
- 后续素材管线优先使用正式美术、IMAGE2 或人工资产，不继续堆代码生成素材。
- 打击特效与角色 / 敌人动作动画分离，方便未来替换武器和动作资源。
- 当前视觉方向是高可读性的 2D / 2.5D 暗黑刷宝体验，场景保持冷峻通天塔世界观，人物和敌人素材可继续尝试像素化或手绘化方案。

## 推荐阅读顺序

1. `docs/NEW_THREAD_HANDOFF.md`
2. `docs/design/2026-06-04-design-compendium.md`
3. `docs/content/2026-06-04-content-production-brief.md`
4. `docs/progress/2026-06-04-new-project-first-playable-progress.md`
5. `docs/planning/` 下最新 ROADMAP 表格

## 回归测试

PowerShell 示例：

```powershell
$godot = 'D:\Godot\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe'
$project = (Resolve-Path '.').Path
$log = Join-Path $project '.godot\regression.log'
$tests = Get-ChildItem -Path "$project\tests\regression" -File -Filter '*.gd' | Sort-Object Name | ForEach-Object { 'res://tests/regression/' + $_.Name }
foreach ($test in $tests) {
  Write-Host "RUN $test"
  & $godot --headless --log-file $log --path $project --script $test
  if ($LASTEXITCODE -ne 0) {
    Write-Host "FAILED $test EXIT $LASTEXITCODE"
    exit $LASTEXITCODE
  }
}
Write-Host 'ALL_NEW_PROJECT_REGRESSION_OK'
```

Godot 退出时可能出现 `ObjectDB instances leaked` / `resources still in use` 警告；目前只要退出码为 0 且完整回归通过，就按非阻断清理项处理。

## 下一步方向

短期优先级：

1. 让冰矛穿透与分裂属性真正改变弹道行为。
2. 增加宝石选择、替换和取下界面。
3. 完成 10 分钟游侠挂机刷宝试玩与数值调整。
4. 扩展自动拾取过滤、危险规避和挂机构筑摘要。
5. 在通用系统上制作战士、法师和侍僧的首套代表性 Build。

## 2026-06-14 更新：游侠 CoC 与宝石刷宝闭环

- 完成游侠寒冰射击暴击触发冰矛的第一版战斗循环。
- 手动与挂机模式共用技能、暴击和触发冷却规则。
- 新增寒霜、精准、迅捷、穿透和分裂宝石。
- 宝石可从刷图掉落进入背包，并镶嵌到已装备物品。
- 装备详情显示孔位、已镶宝石和 Build 相关作用说明。
- 完成主要游戏界面和战斗信息中文化。
- 详细记录见 `CHANGELOG.md` 与 `docs/progress/2026-06-14-localization-gem-loot-loop-progress.md`。

## 2026-06-10 更新：废品批量处理前置

- 新增 `InventoryItemActionService`，集中处理背包物品操作规则。
- 新增废品批量出售/分解预览与执行接口，后续商人和铁匠窗口可直接复用。
- 锁定、收藏、已装备、不可出售物品会被自动保护，不会被批量处理。
- 背包窗口新增 `SellJunkButton` 与 `SalvageJunkButton`，先以文字按钮保留正式图标素材接口。
- 新增回归：`regression_inventory_junk_batch_actions.gd`。

## License

未定。正式发布或对外协作前需要补充许可说明。
