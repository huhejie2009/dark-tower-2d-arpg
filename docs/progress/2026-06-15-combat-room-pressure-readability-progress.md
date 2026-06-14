# 战斗房间、神罚压力与可读性推进记录

日期：2026-06-15

## 本轮目标

根据《33 Immortals》参考适配方案，先补齐适合当前项目阶段的 P2/P3 基础接口：房间目标、神罚压力预警、敌人攻击可读性 QA。当前阶段仍以单机暗黑刷宝/爬塔 ARPG 为核心，不引入多人或每局遗物构筑。

## 完成内容

- 新增 `RoomObjectiveService`：
  - 支持 `clear_all`、`defeat_elite`、`defeat_boss` 三类目标。
  - 根据楼层模板生成目标状态和 HUD 文案。
  - 击杀敌人后推进目标进度。
- Game2D 接入房间目标状态：
  - 楼层刷怪时创建目标状态。
  - 敌人死亡时更新目标进度。
  - 暴露 `get_room_objective_state_for_test()` 供 QA 使用。
- HUD 新增紧凑目标文本：
  - 显示 `Objective: ...`。
  - 保留生命、魔力、经验和背包提示位置。
- 新增 `DivinePressureService`：
  - 神罚事件最少 `0.6s` 预警。
  - 普通怪不触发，精英/Boss 可触发。
  - 已有神罚事件时不重复触发。
- Game2D 接入最小神罚预警：
  - 精英/Boss 死亡后可触发冷色地面预警。
  - 预警结束后生成冲击 VFX。
  - 玩家站在范围内会受到一次神罚伤害。
  - 当前不阻塞传送门。
- 敌人新增攻击可读性 QA 快照：
  - 固定 `idle/run/attack/death` 为必需动画状态。
  - 固定打击 VFX 与身体动画分层。
  - 暴露攻击预警基线和当前攻击状态。

## 明确未做

- 未加入局内遗物。
- 未加入每局构筑。
- 未加入多人协作或网络同步。
- 未替换正式角色/敌人素材。
- 未新增复杂随机地图。
- 未做神罚随机惩罚表。

## 验证记录

聚焦验证通过：

- `NEW_PROJECT_ROOM_OBJECTIVE_SERVICE_OK`
- `NEW_PROJECT_ROOM_OBJECTIVE_HUD_CONTRACT_OK`
- `NEW_PROJECT_DIVINE_PRESSURE_SERVICE_OK`
- `NEW_PROJECT_DIVINE_PRESSURE_GAME2D_CONTRACT_OK`
- `NEW_PROJECT_ENEMY_ATTACK_READABILITY_CONTRACT_OK`
- `NEW_PROJECT_FLOOR_CLEAR_PORTAL_OK`
- `NEW_PROJECT_SCENE_BOOT_ALL_OK`

额外敌人相关验证通过：

- `NEW_PROJECT_ENEMY_ANIMATION_READABILITY_CONTRACT_OK`
- `NEW_PROJECT_ENEMY_ANIMATION_STATE_PLAYBACK_OK`
- `NEW_PROJECT_ENEMY_BEHAVIOR_SERVICE_OK`
- `NEW_PROJECT_ENEMY_BEHAVIOR_STATE_OK`
- `NEW_PROJECT_ENEMY_DEATH_ONCE_OK`

## 后续建议

1. 做一次实机视觉 QA，确认 HUD 目标文本在 1280x720 和移动窗口下不遮挡战斗。
2. 给神罚预警增加 authored VFX 素材接口，后续替换当前临时程序化预警。
3. 基于房间目标服务扩展第一版“精英房/事件房”节奏，但仍不要引入局内遗物。
