# 2026-06-16 2.5D 原型空场景可见性修复进度

## 问题

试玩反馈：进入塔后，2.5D 原型场景里看起来什么都没有。

## 根因

原型场景的结构已经存在：相机、房间、墙体、柱子、玩家、敌人和出口都会运行时生成。但第一版只验证了节点存在，没有验证实机可见性。

具体问题：

- 3D 场景缺少明确的 `WorldEnvironment`。
- 灰盒地面、墙体、柱子和出口缺少显式可见材质。
- 纸片角色当前还没有正式 Sprite 贴图，运行时缺少可见标记。
- 场景没有 HUD 或模式提示，黑背景下容易被误认为空场景。

## 已修复

- 新增世界环境和可见背景色。
- 新增主方向光。
- 给地面、墙体、柱子和出口补充灰盒可见材质。
- 给玩家和敌人补充临时可见标记：
  - 蓝色：玩家。
  - 红色：敌人。
- 新增左上角 2.5D 原型调试 HUD。
- 新增可见性回归测试：
  - `regression_prototype_2_5d_visibility_contract.gd`

## 验证

已使用 Godot 运行当前原型场景并抓取游戏画面，画面中可见：

- 灰盒房间。
- 四周墙体。
- 两根柱子。
- 蓝色玩家标记。
- 两个红色敌人标记。
- 蓝色出口标记。
- 左上角 `2.5D PROTOTYPE` 提示。

专项回归通过：

```text
NEW_PROJECT_PROTOTYPE_2_5D_VISIBILITY_CONTRACT_OK
NEW_PROJECT_ACTIVE_GAME_MODE_2_5D_OK
NEW_PROJECT_PROTOTYPE_2_5D_SCENE_CONTRACT_OK
NEW_PROJECT_PROTOTYPE_2_5D_VISUAL_QA_CONTRACT_OK
NEW_PROJECT_SCENE_BOOT_ALL_OK
NEW_PROJECT_2_5D_VISIBILITY_FIX_REGRESSION_OK
```

Godot headless 退出时仍会打印项目既有的 `ObjectDB instances leaked` / `resources still in use` 警告；本轮专项回归退出码为 0。

## 下一步

这个修复只解决“能看见原型”的问题，不代表它已经是可玩的战斗房间。下一步应补：

- 玩家 WASD 在 3D XZ 平面移动。
- 敌人追击玩家。
- 清怪后出口流程。
- 用截图 QA 调整相机角度、房间比例和纸片角色尺寸。
