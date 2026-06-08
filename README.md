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
- 背包、装备、装备评分、装备推荐与对比摘要
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

- `ALL_NEW_PROJECT_REGRESSION_OK COUNT 100`
- `HEADLESS_BOOT_EXIT 0`
- `NO_RESIDUAL_GODOT_PROCESS`

Godot 退出时可能出现 `ObjectDB instances leaked` / `resources still in use` 警告；目前只要退出码为 0 且完整回归通过，就按非阻断清理项处理。

## 下一步方向

短期优先级：

1. 把主城塔前准备面板视觉化为更正式的暗黑刷宝 UI。
2. 给塔前准备面板加入建议事项：可用技能点、可装备升级、背包空间、推荐起始层。
3. 继续完善 HUD、背包、装备、技能与死亡结算体验。
4. 准备正式 2D 人物、敌人、动作和环境素材替换。
5. 扩展 3 到 5 个楼层节奏变化，并增加更稳定的连续楼层测试。

## License

未定。正式发布或对外协作前需要补充许可说明。
