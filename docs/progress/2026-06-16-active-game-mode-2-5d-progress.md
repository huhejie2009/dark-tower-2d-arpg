# 2026-06-16 当前游戏模式切换到 2.5D 原型

## 本轮目标

根据试玩方向，将“进入游戏/进塔”的当前游戏模式切换到最新制作的 2.5D 纸片角色原型。

## 已完成

- 新增 `PROTOTYPE_2_5D_COMBAT_SCENE` 常量，明确记录 2.5D 原型场景路径。
- 新增 `ACTIVE_GAME_SCENE` 常量，当前指向 2.5D 原型。
- `SceneRouter.go_to_game()` 改为进入 `ACTIVE_GAME_SCENE`。
- 旧 `GAME_2D_SCENE` 仍保留为 `res://scenes/Game2D.tscn`，便于回归、对比和回退。
- 新增 active game mode 回归测试。

## 保护边界

- 未清空、覆盖或迁移玩家存档。
- 未删除旧 2D 战斗场景。
- 未改变主菜单、职业选择、主城场景本身。
- 本轮只是把“进入游戏/进塔”的路由切到 2.5D 原型。

## 验证

```text
NEW_PROJECT_ACTIVE_GAME_MODE_2_5D_OK
NEW_PROJECT_PROTOTYPE_2_5D_SCENE_CONTRACT_OK
NEW_PROJECT_PROTOTYPE_2_5D_VISUAL_QA_CONTRACT_OK
NEW_PROJECT_SCENE_BOOT_ALL_OK
NEW_PROJECT_ACTIVE_2_5D_MODE_REGRESSION_OK
```

Godot headless 退出时仍会打印项目既有的 `ObjectDB instances leaked` / `resources still in use` 警告；本轮专项回归退出码为 0。

## 下一步建议

进入主城后点击进塔，实际观察 2.5D 原型画面。如果镜头、空间和纸片角色方向成立，下一步补玩家可控移动、敌人追击、清怪出口和截图 QA。
