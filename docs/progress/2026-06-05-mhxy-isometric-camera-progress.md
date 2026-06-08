# 2026-06-05 梦幻西游式等距视角调整进度

## 背景

试玩反馈指出当前视角不像目标效果，参考图更接近《梦幻西游》的 2D 等距视角：斜向地砖、宽镜头、前后景层级、屋檐/栏杆/墙体遮挡感，而不是元气骑士式近俯视房间。

## 本轮目标

先调整程序化 2D 战斗场景的镜头语言和场景骨架，让视觉方向切到“梦幻西游式等距”。本轮不重做寻路坐标系，避免破坏移动、碰撞、传送门、清层和掉落等已稳定玩法。

## 已完成

- `Game2D.gd` 中将视觉模式从 `pseudo_34` 调整为 `mhxy_isometric`。
- 镜头从近距离俯视改为更宽的等距视角基准。
- 提高场景斜切强度，并把纵深压缩到更接近等距 2D 场景的比例。
- 将地面节点改为：
  - `MHXYIsometricFloor`
  - `MHXYDiagonalTileGrid`
  - `MHXYRoomBorder`
- 新增前后层级节点：
  - `MHXYBackWallLayer` / `MHXYBackWall`
  - `MHXYRoofEaveLayer` / `MHXYRoofEave`
  - `MHXYForegroundRailingLayer` / `MHXYForegroundRailing`
- 门和墙的语义命名切到新视角：
  - `MHXYNorthDoor`
  - `MHXYSouthDoor`
  - `MHXYNorthWall`
  - `MHXYSouthWall`
  - `MHXYWestWall`
  - `MHXYEastWall`
- 更新回归契约，明确要求：
  - 视觉模式为 `mhxy_isometric`
  - 镜头比旧 pseudo 3/4 更宽
  - 纵深明显压缩
  - 至少存在后墙、屋檐、前景栏杆三层视觉结构
- 更新清层开门/传送门契约，使用新的 `MHXYSouthDoor`。

## 验证结果

- 视角契约：
  - `NEW_PROJECT_PSEUDO_34_VISUAL_CONTRACT_OK`
  - `NEW_PROJECT_PSEUDO_34_ROOM_NAVIGATION_CONTRACT_OK`
- 门/传送门契约：
  - `NEW_PROJECT_FLOOR_CLEAR_DOOR_PORTAL_CONTRACT_OK`
- 完整回归：`ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动：`HEADLESS_EXIT 0`
- 最终进程检查无 Godot 残留进程输出。

## 未触碰范围

- 没有清除玩家存档。
- 没有改动存档结构。
- 没有回到旧 3D 项目。
- 没有恢复 POLYGON 资源。
- 没有导入正式 IMAGE2 角色或场景素材。
- 没有把战斗逻辑坐标改成真正等距坐标系，当前仍保持稳定的 2D 碰撞/移动底座。

## 当前限制

- 本轮是程序化视觉骨架调整，画面仍不是最终美术。
- 角色、怪物和掉落仍是当前程序化占位外观。
- 真正的遮挡排序、屋檐压角色、建筑半透明等更精细规则还没有接入。

## 下一步建议

1. 做一次实机截图检查，继续微调斜切、镜头缩放和前景栏杆位置。
2. 给玩家、敌人和掉落增加 Y-sort / z-index 规则，让等距前后遮挡更自然。
3. 保留当前 IMAGE2 角色接口，后续直接接入 2D 人物 SpriteSheet。
4. 后续场景美术可按“地面层、后墙层、屋檐层、前景遮挡层”四层产出。
