# 2026-06-16 2.5D 纸片角色原型进度

## 本轮目标

建立一个独立 2.5D 原型切片，用于验证“3D 房间 + 2D Sprite3D 角色”的方向是否值得正式迁移。

## 已完成

- 新增 XZ 平面战斗数学服务。
- 新增 2D billboard 角色动画 profile 契约。
- 新增 Sprite3D billboard 角色节点契约。
- 新增独立 2.5D 战斗房间原型场景。
- 新增视觉 QA 快照契约。
- 将原型场景纳入 scene boot，但未接入主菜单和正式流程。

## 保护边界

- 未清空、覆盖或迁移玩家存档。
- 未修改主菜单入口。
- 未替换当前正式 `Game2D.tscn`。
- 未把背包、装备、主城、商人、仓库系统迁入 3D。

## 验证

```text
NEW_PROJECT_2_5D_PROTOTYPE_REGRESSION_OK
NEW_PROJECT_SCENE_BOOT_ALL_OK
```

Godot headless 退出时仍会打印项目既有的 `ObjectDB instances leaked` / `resources still in use` 警告；本轮专项回归退出码为 0。

## 下一步建议

使用 Godot 编辑器或截图工具观察 `res://scenes/prototypes/Prototype2_5DCombatRoom.tscn` 的实际画面。如果空间、遮挡和角色纸片感可接受，再进入“玩家可控移动 + 敌人追击 + 清怪出口”的第二轮原型。
