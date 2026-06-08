# 2026-06-05 IMAGE2 死亡动画入口进度

## 本轮目标

继续推进 IMAGE2 角色素材接入接口，为玩家和敌人补 `death` 动画入口。后续正式素材接入后，死亡表现可以直接通过 manifest 中的 `death` 动画段播放。

## 已完成

- `Player2D.gd`：
  - 新增 `death_animation_triggered` 状态。
  - 玩家受到致命伤害时，会先调用 `_trigger_death_animation()`。
  - 如果 manifest 中存在 `death` 动画，会切换到 `death` 起始帧。
  - `get_actor_animation_state()` 会返回 `death_animation_triggered`。
- `Enemy2D.gd`：
  - 新增同样的 `death_animation_triggered` 状态。
  - 敌人受到致命伤害时，会先切换 `death` 动画，再走现有死亡爆炸、死亡信号和释放流程。
  - `get_actor_animation_state()` 会返回 `death_animation_triggered`。
- 新增回归测试：
  - `tests/regression/regression_actor_death_animation_contract.gd`

## 当前 manifest 示例

```gdscript
{
	"animations": {
		"death": {"from": 3, "to": 3, "fps": 6}
	}
}
```

## 验证结果

- 单项回归：`NEW_PROJECT_ACTOR_DEATH_ANIMATION_CONTRACT_OK`
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

- 当前是死亡动画入口，不是完整死亡动画播放流程。
- 敌人仍会按现有逻辑 `queue_free()`，不会等待 death 动画播完。
- 玩家死亡后仍会进入现有死亡结算流程。

## 下一步建议

1. 为敌人增加 death 动画延迟释放，让正式素材可以播完整死亡动作。
2. 为玩家死亡结算前增加短暂死亡表现窗口。
3. 等 IMAGE2 生成第一套素材后，用 manifest 接入玩家 idle/run/attack/death 实机验证。
