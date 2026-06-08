# 2026-06-05 HUD 等级与经验条进度

## 目标

接上上一轮经验与升级系统，让玩家在战斗 HUD 中直接看到等级、经验进度和技能点，提升刷怪升级的即时反馈。

## 已完成

- `HudController.gd`
  - HUD 节点稳定命名为 `HudController`。
  - 新增 `LevelLabel`。
  - 新增 `ExperienceBar`。
  - 新增 `SkillPointLabel`。
  - 新增 `set_player_progress(level, current_exp, exp_to_next_level, skill_points)`。
- `Game2D.gd`
  - 创建 HUD 时设置稳定节点名。
  - `_update_hud()` 每次刷新时同步：
    - 玩家等级。
    - 当前经验。
    - 下一级所需经验。
    - 可用技能点。

## 新增回归测试

- `regression_hud_level_experience_contract.gd`
  - 覆盖 HUD 等级标签存在。
  - 覆盖经验条存在并同步数值。
  - 覆盖技能点文本存在并同步数值。

## 验证结果

- 单项回归：
  - `NEW_PROJECT_HUD_LEVEL_EXPERIENCE_CONTRACT_OK`
  - `NEW_PROJECT_GAME2D_ENEMY_EXPERIENCE_BRIDGE_OK`
  - `NEW_PROJECT_GAME2D_INPUT_CONTRACT_OK`
- 完整回归：`ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动：`HEADLESS_EXIT 0`
- 最终进程检查无 Godot 残留进程输出。

## 未触碰范围

- 没有清除玩家存档。
- 没有改动存档结构或版本号。
- 没有回到旧 3D 项目。
- 没有恢复 POLYGON 资源。
- 没有新增技能树或技能点消费逻辑。

## 当前限制

- HUD 仍是功能型 UI，美术皮肤还未统一到新世界观方向。
- 经验条只是基础进度条，尚未加入升级动画、音效或闪光反馈。
- 技能点只能显示，暂时不能消费。

## 下一步建议

1. 在背包/角色窗口中显示等级、经验和技能点。
2. 做第一版技能点消费或基础技能升级。
3. 给升级加入视觉/音效反馈。
