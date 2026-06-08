# 2026-06-06 游戏内俯视生产视角规范

## 结论

游戏内视角从偏“梦幻西游式斜 45 度/伪 3/4”调整为“生产友好俯视 2D”。

概念图仍然可以保持宏大、冷峻、史诗、通天塔远景；但游戏内素材、碰撞和房间制作统一按俯视 2D 规则生产。

## 视角目标

- 地图逻辑：纯 2D 俯视。
- 摄像机：中性缩放 `1.0 x 1.0`，不再用纵向压缩制造斜透视。
- 角色素材：轻微俯视或正面 3/4，但脚底锚点必须清晰。
- 敌人素材：以脚底为位置中心，动作条保持透明底。
- 场景素材：允许墙体、柱体、前景遮挡表现高度，但不可让视觉高度等于碰撞体积。

## 碰撞规则

角色、敌人、掉落和门的交互都以脚底位置为准。

推荐碰撞形状：

- 玩家：脚底小圆。
- 普通敌人：脚底小圆。
- 大型敌人/Boss：更大的脚底圆或椭圆近似。
- 墙体：清晰矩形边界。
- 柱子/高障碍物：只在柱脚放碰撞体。

柱子必须拆成两层：

- `视觉层`：整根柱子或上半部分，可遮挡角色，不参与移动阻挡。
- `柱脚碰撞层`：小矩形或小圆，只覆盖地面占位。

## 遮挡规则

所有可排序角色和高障碍物按脚底 `global_position.y` 排序。

基本规则：

- 脚底更靠上：显示在后面。
- 脚底更靠下：显示在前面。
- 柱子上半部分可以视觉遮挡角色，但不能因为视觉高度阻挡角色移动。

## 当前运行时落地

`Game2D.gd` 当前契约：

- `ROOM_VISUAL_MODE = "topdown_production"`
- `camera_zoom = Vector2(1.0, 1.0)`
- `visual_vertical_compress = 1.0`
- 房间根节点：`TopDownFloor`
- 地面网格：`TopDownTileGrid`
- 柱子视觉：`TopDownColumnVisual`
- 柱脚碰撞：`TopDownColumnFootprintBody`
- 出口门：`TopDownSouthDoor`

## IMAGE2 素材提示词要求

后续生成游戏内角色、怪物、Boss、场景件时，应明确写入：

- top-down 2D game sprite
- slight front-facing 3/4 tilt
- clear foot anchor
- transparent or chroma-key removable background
- no steep isometric angle
- no cinematic low angle
- no ornate Chinese palace architecture
- cold brutalist concrete tower interior
- dark blue-black vertical light channels

## 不再使用的游戏内方向

- 不再追求梦幻西游式斜 45 度场景。
- 不再让地面纵向压缩来制造透视。
- 不再让整根柱子或整面高墙作为碰撞体。
- 不再用复杂斜四边形作为默认房间障碍物。

## 后续建议

1. 继续把函数和测试文件名中的 `pseudo_34` 逐步迁移为 `topdown`，但不急于一次性重命名。
2. 按新视角重新生成 Boss 和玩家动作素材。
3. 后续可增加一层调试显示：脚底锚点、碰撞圆、柱脚碰撞矩形。
