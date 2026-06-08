# 2026-06-07 多方向 IMAGE2 Manifest 管线进度

本轮继续推进正式多方向素材管线。上一轮已经做了 `runtime_flip_2dir` 桥接，让当前单方向素材具备左右翻转和换脚表现；本轮把运行时升级为可直接读取 4 向/8 向 IMAGE2 帧条。

## 实现内容

- `Player2D.gd`
  - 新增方向帧偏移读取：
    - `direction_mode`
    - `direction_frame_offsets`
  - `ActorSprite.region_rect` 改为使用 `resolved_frame_index`。
  - `4dir` / `8dir` 模式下不再水平翻转。
  - 测试状态会暴露：
    - `direction_mode`
    - `resolved_frame_index`
    - `direction_frame_offset`

- `Enemy2D.gd`
  - 与玩家同步支持方向帧偏移。
  - 敌人、Boss 后续可以直接换成 4 向/8 向 spritesheet。

- `FloorRules.gd`
  - 当前普通敌人和 Boss v3 manifest 明确标记为 `runtime_flip_2dir`。

- `Game2D.gd`
  - 当前默认玩家 v3 manifest 明确标记为 `runtime_flip_2dir`。

## 新增测试

- `tests/regression/regression_actor_directional_manifest_contract.gd`

测试创建 80 帧 4 向测试图，并验证：

- `down` 方向 run 帧解析到 `4`。
- `left` 方向 run 帧解析到 `24`。
- `right` 方向 run 帧解析到 `44`。
- `up` 方向 run 帧解析到 `64`。
- `4dir` 模式不再使用 `flip_h`。

## 文档

新增素材管线文档：

- `docs/content/2026-06-07-directional-image2-actor-pipeline.md`

文档说明：

- 当前 `runtime_flip_2dir` 的定位。
- 4 向帧条推荐排列。
- 8 向帧条扩展方式。
- IMAGE2 生成提示词约束。
- manifest 示例。

## 聚焦验证

已通过：

- `NEW_PROJECT_ACTOR_DIRECTIONAL_MANIFEST_CONTRACT_OK`
- `NEW_PROJECT_ACTOR_DIRECTIONAL_FOOTSTEP_PRESENTATION_OK`
- `NEW_PROJECT_DEFAULT_IMAGE2_PLAYER_ART_CONTRACT_OK`
- `NEW_PROJECT_ROT_MELEE_IMAGE2_MANIFEST_OK`
- `NEW_PROJECT_SHADOW_ARCHER_IMAGE2_MANIFEST_OK`
- `NEW_PROJECT_TOWER_GUARDIAN_IMAGE2_MANIFEST_OK`
- `NEW_PROJECT_GAME2D_BOSS_SPAWN_OK`
- `NEW_PROJECT_ACTOR_SPRITESHEET_ANIMATION_CONTRACT_OK`
- `DIRECTIONAL_IMAGE2_MANIFEST_FOCUSED_OK`

## 下一步建议

1. 先生成玩家战士 4 向 v1，不要一次做全职业。
2. 如果玩家 4 向接入稳定，再生成 `rot_melee` 4 向 v1。
3. Boss 建议暂时仍使用 `runtime_flip_2dir`，等普通单位 4 向稳定后再做 Boss 4 向。
