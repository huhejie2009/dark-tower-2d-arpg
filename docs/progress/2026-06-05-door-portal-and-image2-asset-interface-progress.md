# 2026-06-05 门/传送门与 IMAGE2 素材接口进度

## 本轮目标

继续推进 C 方案伪 3/4 房间体验，让清怪后的出口门有点亮反馈，传送门出现在门附近。同时预留 2D 人物素材动画接口，方便后续直接接入 IMAGE2 生成的角色、怪物序列帧。

## 已完成

- `Game2D.gd`：
  - 南门 `Pseudo34SouthDoor` 默认处于未激活状态。
  - 清怪后调用 `_activate_exit_door()`，南门会被标记为 active 并变成更亮的蓝色。
  - 新增 `active_exit_door_position`，作为当前出口门锚点。
  - 传送门现在生成在出口门附近，并继续走安全出生点校正。
  - 新增测试入口：
    - `_clear_floor_for_test()`
    - `_get_active_exit_door_position_for_test()`
- `Player2D.gd`：
  - 新增 `ActorVisualRoot`，作为未来生成素材的挂载根节点。
  - 新增 `ActorSprite`，作为未来 SpriteSheet/序列帧的 Sprite2D 接入口。
  - 新增 visual asset manifest 接口：
    - `apply_visual_asset_manifest()`
    - `get_visual_asset_manifest()`
    - `apply_visual_asset_manifest_for_test()`
    - `get_visual_asset_manifest_for_test()`
- `Enemy2D.gd`：
  - 新增同样的 `ActorVisualRoot` 与 `ActorSprite`。
  - 新增同样的 visual asset manifest 接口。
- 新增回归测试：
  - `tests/regression/regression_floor_clear_door_portal_contract.gd`
  - `tests/regression/regression_actor_visual_asset_interface.gd`

## IMAGE2 接口说明

当前还没有生成或导入正式 2D 人物素材。接口先保留以下 manifest 结构：

```gdscript
{
	"asset_pipeline": "image2",
	"sprite_sheet_path": "res://assets/generated/actors/player_sheet.png",
	"frame_size": Vector2i(64, 64),
	"animations": {
		"idle": {"from": 0, "to": 3, "fps": 8},
		"run": {"from": 4, "to": 9, "fps": 10},
		"attack": {"from": 10, "to": 15, "fps": 12},
	}
}
```

后续 IMAGE2 生成角色或怪物动画后，可以把素材路径和动画帧信息写入 manifest，再由角色脚本加载到 `ActorSprite` 或升级为 `AnimatedSprite2D` / `SpriteFrames`。

## 验证结果

- 单项回归：`NEW_PROJECT_FLOOR_CLEAR_DOOR_PORTAL_CONTRACT_OK`
- 单项回归：`NEW_PROJECT_ACTOR_VISUAL_ASSET_INTERFACE_OK`
- 完整回归：`ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动：`HEADLESS_EXIT 0`
- Godot 测试残留进程检查：未列出残留 `Godot_v4.6.2-stable_win64` 进程

## 未触碰内容

- 未清除玩家存档。
- 未改动存档 schema。
- 未生成或导入人物图片素材。
- 未恢复旧 3D 项目资源。
- 未恢复 POLYGON 资源。

## 下一步建议

1. 建立 `assets/generated/actors/` 目录约定和素材命名规范。
2. 为 `ActorSprite` 增加真正的 SpriteSheet 加载与帧切换逻辑。
3. 让门点亮时增加短暂闪光或描边动画。
4. 将大房间逐步拆成小房间节奏，让门、传送门和障碍形成更完整的闯关感。
