# 2026-06-17 2.5D Billboard 动画播放骨架进度

## 背景

上一轮已经把玩家攻击动作状态和独立命中特效拆开，但 `idle/run/attack/death` 仍只是语义状态，还没有接到统一的帧动画播放接口。本轮按推荐继续推进“先让游戏看起来像游戏”的底层链路：先做动画播放器骨架和素材接口，不制作新的正式素材。

## 本轮完成

- `BillboardActor3D` 新增帧动画播放骨架：
  - 支持 `apply_visual_asset_manifest()` 接入动画 manifest。
  - 支持 `idle/run/attack/death` 动画切换。
  - 支持 `tick_actor_animation()` 按 fps 推进帧号。
  - 支持 `direction_mode = "4dir"` 和 `direction_frame_offsets`，为四方向素材预留接口。
  - 支持 Sprite3D `region_rect` 切帧。
  - 保留 `ActorSprite` 与 `WeaponSprite` 分离，避免把武器画死在身体帧里。
- `Prototype2_5DCombatRoom` 新增动画状态同步：
  - 玩家移动同步到 `run`。
  - 玩家攻击同步到 `attack`。
  - 攻击收束后回到 `idle/run`。
  - 敌人追击同步到 `run`，攻击同步到 `attack`，死亡同步到 `death`。
- 新增测试接口：
  - `get_actor_animation_state_for_test()`
  - `update_actor_animation_state_for_test()`
  - `tick_actor_animation_for_test()`
  - `build_animation_state_snapshot_for_test()`
- 新增回归测试：
  - `tests/regression/regression_billboard_actor_3d_animation_player.gd`
  - `tests/regression/regression_prototype_2_5d_animation_state_sync.gd`

## 验收标准

- Billboard 演员可以从 manifest 读取动画帧区间、fps、循环/一次性播放配置。
- 移动状态切换到 `run`，攻击状态切换到 `attack`，死亡状态切换到 `death`。
- 四方向偏移能影响 `resolved_frame_index`，后续接正式四方向素材时不需要改战斗逻辑。
- 攻击和死亡等一次性动画能停在末帧，避免帧播放乱跳。
- 玩家身体层和武器层保持分离。
- 2.5D 战斗场景能把玩家/敌人的战斗状态同步到动画播放器。

## 后续建议

1. 接入第一批正式/半正式像素角色帧序列，验证 `idle/run/attack/death` 的实际可读性。
2. 给武器层增加独立动画 manifest，让换武器不需要重做人物身体帧。
3. 给敌人增加受击状态或受击打断窗口，和独立命中特效、伤害飘字对齐。
4. 做实机视觉 QA：录制玩家移动、攻击、敌人死亡的短片，逐帧检查动作是否清楚。

## 注意

- 本轮不修改玩家存档，不触发真实爬塔进度保存。
- 本轮不生成新美术素材，默认 2.5D manifest 是运行时占位动画表。
- 这一步主要是为 IMAGE2、像素角色、武器分层和正式 VFX 替换铺接口。
