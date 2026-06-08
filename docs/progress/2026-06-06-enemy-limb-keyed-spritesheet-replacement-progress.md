# 2026-06-06 敌人肢体关键帧帧条替换进度

## 问题修正

试玩反馈指出：敌人并不是在播放真正的动作动画，而是静止图片在左右晃动。

这次修正重点从“运行时状态机”转为“素材帧本身必须有姿态变化”：

- 移动时要能看出迈步。
- 攻击时要能看出挥臂、挥锤或拉弓。
- 死亡时要能看出倒下或塌落。

## 已完成

替换了三套敌人 spritesheet，保持原路径不变，避免重接场景和 manifest：

- `res://assets/generated/actors/enemy_rot_melee_sheet_v1.png`
- `res://assets/generated/actors/enemy_shadow_archer_sheet_v1.png`
- `res://assets/generated/actors/enemy_tower_guardian_sheet_v1.png`

旧素材已非破坏备份：

- `enemy_rot_melee_sheet_v1_static_backup.png`
- `enemy_shadow_archer_sheet_v1_static_backup.png`
- `enemy_tower_guardian_sheet_v1_static_backup.png`

新帧条仍然保持：

- 单帧尺寸：`128x128`
- 总帧数：`20`
- `idle`: 0-3
- `run`: 4-9
- `attack`: 10-15
- `death`: 16-19

## Manifest 更新

`scripts/rules/FloorRules.gd` 中三套敌人 manifest 新增：

```gdscript
"pose_variation_version": "limb_keyed_v2"
```

用于标记当前帧条已经不是静态抖动版，而是肢体关键帧版。

## 新增测试

新增图像级回归测试：

- `tests/regression/regression_enemy_spritesheet_pose_variation.gd`

测试会直接读取 PNG 帧条，检查每个动画段的透明轮廓/重心变化：

- `idle` 要有轻微呼吸或位移。
- `run` 要有清晰迈步轮廓。
- `attack` 要有明显手臂、武器或弓箭延展。
- `death` 要有明显倒下/塌落变化。

## 验证结果

- Godot 导入：
  - `EDITOR_IMPORT_EXIT 0`
- 敌人帧条专项：
  - `NEW_PROJECT_ENEMY_SPRITESHEET_POSE_VARIATION_OK`
- 敌人相关回归：
  - `ENEMY_LIMB_KEYED_SPRITESHEET_REGRESSION_OK`
- 完整回归：
  - `ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动：
  - `MAIN_HEADLESS_EXIT 0`

## 边界

- 没有清除玩家存档。
- 没有修改存档结构。
- 没有回到旧 3D 项目。
- 没有恢复或接入 POLYGON 资源。
- 本次使用确定性生成的临时肢体关键帧帧条，作为可玩阶段占位素材；后续仍可用 IMAGE2 生成更高美术质量版本并替换同一路径或升级到 v2 文件名。

## 下一步建议

1. 进入游戏实机看三类敌人的移动、攻击、死亡是否足够清楚。
2. 如果动作方向认可，再用 IMAGE2 按同样帧段规范生成更精细版本。
3. 后续建议把 Boss `tower_gatekeeper` 单独制作一套更大的攻击/冲锋/死亡帧条。
