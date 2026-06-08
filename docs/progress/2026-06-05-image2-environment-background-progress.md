# 2026-06-05 IMAGE2 环境背景接入进度

## 背景

试玩反馈指出当前程序化多边形画面仍然太抽象，难以继续判断《梦幻西游》式等距视角是否正确。因此本轮先使用 IMAGE2 生成并接入一张可玩的环境背景素材，让战斗场景具备更明确的美术参照。

## 已生成素材

- `res://assets/generated/environments/mhxy_isometric_room_bg_v1.png`

素材内容为 2D 等距暗黑中式塔楼战斗房间背景，包含：

- 斜向石砖战斗区域。
- 后景木质墙体和发光窗格。
- 屋檐、立柱、烛台、楼梯等高层结构。
- 前景栏杆和下沿遮挡感。
- 中央留出较清晰的战斗空间。

## 已完成接入

- `Game2D.gd` 新增环境背景路径常量：
  - `IMAGE2_ENVIRONMENT_BACKGROUND_PATH`
- `Game2D.gd` 新增 `IMAGE2EnvironmentBackground` 背景贴图节点。
- 背景图使用 `Image.load + ImageTexture.create_from_image` 加载，不依赖 Godot `.import` 缓存，适合 IMAGE2 生成图快速接入。
- 当背景图加载成功后，程序化地面、网格、墙、门、屋檐、前景栏杆等视觉层会自动降低透明度，只保留碰撞、契约和轻微辅助线索。
- 新增测试接口 `_get_environment_asset_contract_for_test()`。
- 新增回归测试 `regression_image2_environment_background_contract.gd`，覆盖：
  - 环境素材管线标记为 `IMAGE2`。
  - 背景素材位于 `res://assets/generated/environments/`。
  - 背景贴图可加载。
  - 背景加载后程序化视觉层已降噪。

## 验证结果

- 单项回归：
  - `NEW_PROJECT_IMAGE2_ENVIRONMENT_BACKGROUND_CONTRACT_OK`
  - `NEW_PROJECT_PSEUDO_34_VISUAL_CONTRACT_OK`
  - `NEW_PROJECT_PSEUDO_34_SAFE_SPAWN_POINTS_OK`
  - `NEW_PROJECT_FLOOR_CLEAR_DOOR_PORTAL_CONTRACT_OK`
- 完整回归：`ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动：`HEADLESS_EXIT 0`
- 最终进程检查无 Godot 残留进程输出。

## 未触碰范围

- 没有清除玩家存档。
- 没有改动存档结构。
- 没有回到旧 3D 项目。
- 没有恢复 POLYGON 资源。
- 没有接入正式玩家/敌人 SpriteSheet。

## 当前限制

- 当前是单张完整背景图，前景栏杆暂时不是独立透明遮挡层，所以角色仍会绘制在背景整体之上。
- 程序化碰撞区域还没有完全按图片中的墙体和栏杆重新贴合。
- 角色和敌人仍是程序化占位外观，整体画面还缺少 IMAGE2 角色素材。

## 下一步建议

1. 拆出或生成独立前景遮挡层，让角色经过栏杆/屋檐时有正确遮挡。
2. 生成第一套 IMAGE2 玩家 SpriteSheet，接入 idle/run/attack/death。
3. 按新背景重新微调出生点、传送门位置和敌人出生分布。
4. 继续生成 2 到 3 张不同楼层环境背景，形成爬塔节奏变化。
