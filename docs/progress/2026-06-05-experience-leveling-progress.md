# 2026-06-05 经验与升级系统进度

## 目标

暂停美术探索后，回到游戏功能制作。本轮先补 ARPG 刷怪反馈核心：敌人死亡给予经验，玩家积累经验后升级，并获得基础成长与技能点。

## 已完成

- `PlayerDataService.gd`
  - 标准化 `current_exp`、`exp_to_next_level`、`skill_points` 字段。
  - 新增 `add_experience(player_data, amount)`。
  - 支持经验溢出连续升级。
  - 升级后：
    - `player_level + 1`
    - `skill_points + 1`
    - `max_health` 增加
    - 当前 `health` 随生命上限成长补一段
    - `max_mana` / `mana` 增加
    - `attack_damage` 增加
    - `exp_to_next_level` 提高
- `Game2D.gd`
  - 敌人死亡时自动发放经验。
  - 普通、精英、Boss 根据类型和阶级给不同经验。
  - 获得经验后同步 `player_data`，并重新应用玩家运行时属性。
  - 获得经验会触发延迟保存。
  - HUD 日志会显示 `+XP`，升级时追加 `Level up!`。
  - 新增测试入口 `_award_enemy_experience_for_test(enemy_data)`。
- `Player2D.gd` / `Enemy2D.gd`
  - IMAGE2 图片加载改为 `ProjectSettings.globalize_path()` 后再 `Image.load()`，减少直接加载 `res://` PNG 的导出警告。

## 新增回归测试

- `regression_player_experience_leveling.gd`
  - 覆盖经验溢出升级。
  - 覆盖技能点、生命、攻击、下级经验需求增长。
- `regression_game2d_enemy_experience_bridge.gd`
  - 覆盖 Game2D 敌人经验奖励桥接。

## 验证结果

- 单项回归：
  - `NEW_PROJECT_PLAYER_EXPERIENCE_LEVELING_OK`
  - `NEW_PROJECT_GAME2D_ENEMY_EXPERIENCE_BRIDGE_OK`
  - `NEW_PROJECT_ACTOR_SPRITESHEET_TEXTURE_AND_STATE_OK`
- 完整回归：`ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动：`HEADLESS_EXIT 0`
- 最终进程检查无 Godot 残留进程输出。

## 未触碰范围

- 没有清除玩家存档。
- 没有改动存档版本号。
- 没有回到旧 3D 项目。
- 没有恢复 POLYGON 资源。
- 没有新增技能树 UI 或转职逻辑。

## 当前限制

- 升级数值是第一版保守成长，后续需要按职业差异拆分。
- HUD 只显示简短经验提示，还没有经验条。
- 技能点已经增长，但还没有技能树消费入口。

## 下一步建议

1. 给 HUD 增加等级与经验条。
2. 在角色/背包窗口中显示等级、经验、技能点。
3. 做第一版技能点消费或基础技能升级。
4. 根据职业调整升级成长曲线。
