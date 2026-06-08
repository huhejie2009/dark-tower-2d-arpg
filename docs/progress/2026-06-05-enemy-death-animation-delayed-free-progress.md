# 2026-06-05 敌人死亡动画延迟释放进度

## 本轮目标

继续推进 IMAGE2 角色素材接入体验，让敌人在存在 `death` 动画素材时，不再立即释放节点，而是保留到死亡动画时长结束后再释放。

## 已完成

- `Enemy2D.gd`：
  - 新增 `_get_death_animation_duration()`，根据 manifest 中 `death` 动画的 `from`、`to`、`fps` 计算持续时间。
  - 新增 `_queue_free_after_death_animation()`。
  - 敌人受到致命伤害后：
    - 立即设置 `is_dead = true`
    - 立即触发 `death` 动画入口
    - 立即停止物理处理
    - 立即触发死亡爆炸逻辑
    - 立即发出 `died` 信号，保证掉落、清怪、传送门逻辑不等待动画
    - 如果有启用的 `death` 动画，则延迟释放节点
    - 如果没有启用的 `death` 动画，则保持原来的快速释放
  - 新增 `get_death_animation_duration_for_test()`。
- 新增回归测试：
  - `tests/regression/regression_enemy_death_animation_delayed_free.gd`

## 验证结果

- 单项回归：`NEW_PROJECT_ENEMY_DEATH_ANIMATION_DELAYED_FREE_OK`
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

- 延迟释放只对敌人生效，玩家死亡仍进入现有死亡结算。
- 如果没有启用 `death` 动画，敌人仍快速释放。
- 正式素材还没接入，因此当前只是机制准备。

## 下一步建议

1. 为玩家死亡结算前增加短暂死亡表现窗口。
2. 给敌人 death 动画期间禁用碰撞，避免死亡实体挡路。
3. 接入第一套 IMAGE2 玩家素材，实机验证 idle/run/attack/death。
