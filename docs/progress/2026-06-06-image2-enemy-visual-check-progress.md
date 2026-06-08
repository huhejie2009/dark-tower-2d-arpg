# 2026-06-06 IMAGE2 敌人素材实机检查进度

## 本次目标

对已替换进游戏的三类敌人素材进行一波检查，确认它们在资源层和实际楼层刷怪层都能稳定使用。

检查对象：

- `rot_melee`
- `shadow_archer`
- `tower_guardian`

## 新增检查

- 新增 `res://tests/regression/regression_image2_enemy_asset_visual_quality.gd`
  - 检查三张动作条是否能从磁盘加载。
  - 检查尺寸是否为横向 20 帧、单帧 `128 x 128`。
  - 检查关键帧是否有足够可读的透明像素范围。
  - 检查是否残留可见绿幕背景。
- 扩展 `res://tests/regression/regression_game2d_image2_enemy_replacement.gd`
  - 检查范围从第 1、3、4 层扩展到第 1 到第 5 层。
  - 第 5 层 Boss 还没有制作素材，因此只要求同层普通怪完成替换。

## 检查发现与修复

素材质量检查发现 `enemy_rot_melee_sheet_v1.png` 中仍有少量绿色背景残留。

已处理：

- 清理 `rot_melee` 动作条中的可见绿幕像素。
- 同步更新预览图：
  - `res://docs/concepts/world_art_direction/enemy_rot_melee_sheet_v1_preview.png`
- 通过 Godot headless editor 流程重新导入资源。

## 当前资源状态

- `res://assets/generated/actors/enemy_rot_melee_sheet_v1.png`
- `res://assets/generated/actors/enemy_shadow_archer_sheet_v1.png`
- `res://assets/generated/actors/enemy_tower_guardian_sheet_v1.png`

三张动作条对应 `.import` 文件均已存在。

## 验证结果

- `NEW_PROJECT_IMAGE2_ENEMY_ASSET_VISUAL_QUALITY_OK`
- `NEW_PROJECT_GAME2D_IMAGE2_ENEMY_REPLACEMENT_OK`
- `IMAGE2_ENEMY_VISUAL_CHECKS_OK`
- `ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动退出码：`0`

## 进程状态

- 验证后没有残留本次 headless 测试进程。
- 检测到一个普通 `Godot.exe` 编辑器进程，未关闭。

## 未触碰内容

- 没有清除玩家存档。
- 没有回到旧 3D 项目。
- 没有恢复或接入 POLYGON 资源。

## 推荐下一步

1. 制作并接入 `tower_gatekeeper` Boss 的第一版 IMAGE2 动作条和默认 manifest。
2. 之后进入可视化试玩，重点观察第 5 层 Boss 与小怪同屏时的尺寸关系。
3. 如果 Boss 素材接入稳定，再开始替换玩家角色的移动、攻击、死亡动作条。
