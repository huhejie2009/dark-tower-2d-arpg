# Dark Tower 2D ARPG

Godot 4.6.2 纯 2D / 2.5D 暗黑刷宝爬塔 ARPG 新项目。

当前目标是先把游戏做到稳定可试玩：主城准备、进塔战斗、掉落拾取、背包装备、经验成长、死亡结算和返回主城形成闭环；美术资产继续保留正式素材接入接口，避免继续依赖代码生成素材。

## 当前状态

- 主菜单、职业选择、存档槽和主城流程已接入。
- 2.5D 塔内战斗原型已作为当前主线模式推进。
- WASD / 方向键移动，鼠标攻击，敌人追击、攻击、死亡和掉落已接入。
- 背包、装备、装备评分、装备推荐、物品对比、废品出售/分解、技能点成长、仓库和商人数据底座已接入。
- 打开背包 / 装备窗口时会暂停战斗，避免玩家整理装备时被怪物击杀。
- HUD 显示生命、法力、经验、技能点、装备评分和掉落提示。
- 死亡结算、半血回城、清层奖励、下一层入口和主城返回闭环已接入。
- 核心可见 UI 已完成中文化，包含主菜单、职业选择、主城、背包装备、HUD、掉落提示、死亡结算、楼层提示和设施窗口。
- Godot AI / godot-devtool MCP 已接入，用于项目检查、运行验证和后续编辑器辅助。

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
C:\Users\huhej\OneDrive\桌面\Godot_v4.6.2-stable_win64_console.exe
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

Godot 退出时可能出现 `ObjectDB instances leaked` / `resources still in use` 警告；目前只要退出码为 0 且完整回归通过，就按非阻断清理项处理。

## 下一步方向

1. 继续强化 2.5D 塔内战斗可读性，优先解决敌我动作、攻击预警、受击反馈和死亡反馈。
2. 完善背包 / 装备系统的正式交互体验，包括筛选、排序、对比、出售、分解、仓库和商人窗口。
3. 推进主城功能化，让主城真正承担准备、交易、训练、仓库和进塔入口。
4. 准备正式 2D 人物、敌人、动作和环境素材替换，保留清晰的资产接口。
5. 扩展 3 到 5 个楼层节奏变化，并增加连续爬塔稳定性测试。

## License

未定。正式发布或对外协作前需要补充许可说明。
