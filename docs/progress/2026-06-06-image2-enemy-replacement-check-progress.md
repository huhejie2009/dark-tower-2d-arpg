# 2026-06-06 IMAGE2 敌人素材替换检查进度

## 本次目标

检查已制作的 `rot_melee`、`shadow_archer`、`tower_guardian` 三套 IMAGE2 动作条是否真正替换进游戏运行时，而不是只停留在单体素材测试或规则数据里。

## 检查发现

新增实机场景级检查后发现：

- 单独创建 `Enemy2D` 并调用 `apply_enemy_data()` 时，动作条可以正常加载。
- 但 `Game2D` 楼层刷怪流程中，敌人数据是在敌人加入场景树之前应用的。
- 此时 `ActorSprite` 还没有在 `_ready()` 里创建，导致 manifest 已保存，但贴图没有实际加载，程序化 `EnemyBody` 也没有隐藏。

## 修复内容

- 更新 `res://scripts/combat/Enemy2D.gd`：
  - 在 `_ready()` 创建碰撞和视觉节点后，如果 `visual_asset_manifest` 已存在，就重新应用一次 manifest。
  - 这样 `Game2D` 先套数据、后加入场景树的流程也能正确加载动作条。
- 新增回归测试：
  - `res://tests/regression/regression_game2d_image2_enemy_replacement.gd`
  - 覆盖第 1、3、4 层实际刷出的敌人。
  - 检查内容：
    - 敌人保留 IMAGE2 manifest。
    - `ActorSprite` 已加载贴图。
    - 程序化 `EnemyBody` 已隐藏。

## 当前已替换的敌人素材

- `res://assets/generated/actors/enemy_rot_melee_sheet_v1.png`
- `res://assets/generated/actors/enemy_shadow_archer_sheet_v1.png`
- `res://assets/generated/actors/enemy_tower_guardian_sheet_v1.png`

对应 `.import` 文件均已生成。

## 验证结果

- `NEW_PROJECT_GAME2D_IMAGE2_ENEMY_REPLACEMENT_OK`
- `IMAGE2_ENEMY_REPLACEMENT_RELATED_TESTS_OK`
- `ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动退出码：`0`

## 进程状态

- 验证后没有残留本次 headless 测试进程。
- 检测到一个普通 `Godot.exe` 编辑器进程，未关闭。

## 未触碰内容

- 没有清除玩家存档。
- 没有回到旧 3D 项目。
- 没有恢复或接入 POLYGON 资源。

## 后续建议

1. 在可视化编辑器中实机试玩第 1 到第 5 层，重点看三类敌人的尺寸、脚底锚点和暗色轮廓可读性。
2. 如果普通敌人视觉替换体验稳定，再制作 `tower_gatekeeper` Boss 的第一版动作条。
3. 后续再用更高质量 IMAGE2 逐帧动画替换当前占位动作条。
