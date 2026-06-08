# 2026-06-05 IMAGE2 美术底座 v1 进度

## 目标

在继续制作新功能前，先降低游戏画面的抽象占位感。当前优先级是把最常见、最显眼的对象换成 IMAGE2 生成素材，同时保留程序化回退和已有玩法稳定性。

## 本轮新增素材

- 玩家主角绿幕原图：
  - `res://assets/generated/actors/player_warrior_image2_stand_v1_green.png`
- 玩家主角透明游戏贴图：
  - `res://assets/generated/actors/player_warrior_image2_stand_v1.png`

该角色为中式幻想剑士风格，青金配色，单帧站立姿态。当前作为美术占位 v1 使用，后续仍需生成完整 idle/run/attack/death SpriteSheet。

## 已完成接入

- `Player2D.gd`
  - 将 `PlayerBodyOutline` 纳入程序化占位隐藏列表。
  - 给玩家程序化轮廓节点补稳定名称 `PlayerBodyOutline`。
- `Game2D.gd`
  - 新增 `DEFAULT_PLAYER_IMAGE2_SPRITE_PATH`。
  - 玩家生成后自动应用默认 IMAGE2 manifest。
  - 默认 manifest 使用单帧 160×160 贴图，并设置：
    - `asset_pipeline = "IMAGE2"`
    - `enabled = true`
    - `hide_procedural_body = true`
    - `idle/run/attack` 暂时共用单帧。
  - 新增测试契约 `_get_default_actor_art_contract_for_test()`。
- 新增回归测试：
  - `regression_default_image2_player_art_contract.gd`

## IMAGE2 生成情况

- 环境背景此前已接入：
  - `res://assets/generated/environments/mhxy_isometric_room_bg_v1.png`
- 本轮新增玩家贴图已接入。
- 敌人、掉落和传送门在本轮尝试生成时遇到 IMAGE2 限流，暂未接入，仍保留程序化视觉回退。

## 验证结果

- 单项回归：
  - `NEW_PROJECT_DEFAULT_IMAGE2_PLAYER_ART_CONTRACT_OK`
  - `NEW_PROJECT_IMAGE2_ENVIRONMENT_BACKGROUND_CONTRACT_OK`
- 完整回归：`ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动：`HEADLESS_EXIT 0`
- 最终进程检查无 Godot 残留进程输出。

## 未触碰范围

- 没有清除玩家存档。
- 没有改动存档结构。
- 没有回到旧 3D 项目。
- 没有恢复 POLYGON 资源。
- 没有修改装备、掉落、敌人、楼层数值规则。

## 当前限制

- 玩家目前是单帧贴图，不是完整动画 SpriteSheet。
- 敌人、掉落、传送门仍是程序化占位。
- 角色贴图为较高精度立绘压缩到 160×160，实机中可能还需要微调大小、锚点和遮挡排序。

## 下一步建议

1. 继续生成并接入普通敌人 IMAGE2 单帧贴图。
2. 生成掉落宝物与传送门贴图，替换当前几何图形。
3. 做 Y-sort / z-index 规则，让玩家、敌人、掉落与等距背景前后关系更自然。
4. 再生成完整玩家 SpriteSheet，替换当前单帧临时方案。
