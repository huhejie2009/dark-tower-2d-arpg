# 2026-06-05 IMAGE2 动画自动播放进度

## 本轮目标

继续推进 IMAGE2 角色素材接入接口，让玩家和敌人的 SpriteSheet 动画可以按 manifest 中的 `fps` 自动推进，并在正式贴图启用时隐藏程序化多边形身体。

## 已完成

- `Player2D.gd`：
  - 新增 `tick_actor_animation(delta)`，按当前动画的 `fps` 自动推进帧。
  - `_physics_process()` 中会调用动画 tick。
  - 新增 `hide_procedural_body` manifest 支持。
  - 当 `enabled = true`、`hide_procedural_body = true` 且贴图加载成功时，会隐藏 `PlayerBody` 与 `PlayerFacingHint`。
  - 新增 `tick_actor_animation_for_test()`。
- `Enemy2D.gd`：
  - 新增同样的 `tick_actor_animation(delta)`。
  - `_physics_process()` 中会调用动画 tick。
  - 当 generated sprite 启用并加载成功时，会隐藏 `EnemyBody`。
  - 新增 `tick_actor_animation_for_test()`。
- 新增回归测试：
  - `tests/regression/regression_actor_animation_autoplay_and_visibility.gd`

## Manifest 新增字段

```gdscript
{
	"enabled": true,
	"hide_procedural_body": true,
	"animations": {
		"run": {"from": 1, "to": 2, "fps": 10}
	}
}
```

## 验证结果

- 单项回归：`NEW_PROJECT_ACTOR_ANIMATION_AUTOPLAY_AND_VISIBILITY_OK`
- 完整回归：`ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动：`HEADLESS_EXIT 0`
- Godot 测试残留进程检查：未列出残留 `Godot_v4.6.2-stable_win64` 进程

## 未触碰内容

- 未清除玩家存档。
- 未改动存档 schema。
- 未导入正式 IMAGE2 图片。
- 未恢复旧 3D 项目资源。
- 未恢复 POLYGON 资源。

## 当前限制

- 当前仍缺正式 IMAGE2 角色/敌人素材。
- 只隐藏身体和朝向提示，阴影、血条、名字板仍保留。
- 死亡动画还没有接入。

## 下一步建议

1. 为玩家和敌人加入 `death` 动画入口。
2. 生成第一套 IMAGE2 玩家素材，并用 manifest 接入实机验证。
3. 给敌人类型配置默认素材 manifest 映射。
