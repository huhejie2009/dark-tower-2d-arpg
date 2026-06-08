# 2026-06-07 打击特效分离与方向/换脚表现进度

本轮根据试玩反馈继续调整战斗视觉管线：

- 打击特效应与人物动作分离。
- 当前角色和敌人动画与环境割裂感较强。
- 玩家和敌人跑步缺少方向变化与换脚感。

## 专业管线判断

打击特效不应该画进人物 spritesheet。人物动画只负责身体、武器、重心和朝向；攻击轨迹、命中火花、冲击环、碎屑、范围提示应由独立 VFX 节点按技能逻辑触发。

这样后续才能支持：

- 同一人物动作复用不同武器特效。
- 暴击、元素、护甲、格挡、死亡爆裂等命中反馈独立扩展。
- 命中特效在真实命中点播放，而不是固定在角色帧里。
- Boss 范围提示和地面冲击不污染 Boss 动作帧条。

## 本轮实现

### VFX 分层

- `Vfx2DFactory.gd`
  - `spawn_slash()` 生成 `AttackTrailVFX`。
  - `spawn_hit()` 生成 `HitImpactVFX`。
  - 两类节点都写入 `vfx_role` 元数据，明确它们属于 VFX 层，不属于 actor animation。
  - 颜色调整为更冷的白蓝攻击轨迹，加少量暗红火花，减少和冷塔环境的割裂。

- `Skill2DLibrary.gd`
  - 玩家普通攻击继续由技能逻辑触发独立攻击轨迹和命中冲击。

- `Enemy2D.gd`
  - 敌人近战命中玩家时也会生成独立 `HitImpactVFX`。
  - 远程投射物命中时也触发命中 VFX。

### 方向与换脚表现

当前正式 4/8 方向 IMAGE2 素材尚未制作，因此本轮先做运行时方向表现：

- `Player2D.gd`
  - 不再通过旋转整个 `CharacterBody2D` 表示朝向。
  - `face_world_position()` 改为记录 `facing_direction`。
  - `ActorSprite` 根据朝向做左右翻转。
  - 跑步时加入横向脚步相位、上下 bob 和轻微旋转，增强换脚感。
  - 攻击时按朝向产生轻微 lunge。

- `Enemy2D.gd`
  - 追击时按移动方向更新 `facing_direction`。
  - 攻击时按目标方向更新 `facing_direction`。
  - `ActorSprite` 根据朝向左右翻转。
  - 跑步时加入脚步相位、上下 bob 和轻微旋转。

这不是最终多方向动画替代品，而是第一版可玩阶段的方向/步态桥接。后续正式方案仍应生成 4 方向或 8 方向 spritesheet。

## 新增测试

- `tests/regression/regression_combat_vfx_separation_contract.gd`
  - 验证普通攻击会生成独立 `AttackTrailVFX` 和 `HitImpactVFX`。
  - 验证 VFX 节点不挂在玩家 `ActorSprite` 下。

- `tests/regression/regression_actor_directional_footstep_presentation.gd`
  - 验证玩家左/右朝向会改变 `facing_bucket` 和水平翻转。
  - 验证玩家跑步有脚步偏移或上下 bob。
  - 验证敌人移动时也会翻转并表现换脚。

## 聚焦验证

已通过：

- `NEW_PROJECT_COMBAT_VFX_SEPARATION_CONTRACT_OK`
- `NEW_PROJECT_ACTOR_DIRECTIONAL_FOOTSTEP_PRESENTATION_OK`
- `NEW_PROJECT_ENEMY_ANIMATION_READABILITY_CONTRACT_OK`
- `NEW_PROJECT_ACTOR_SPRITESHEET_TEXTURE_AND_STATE_OK`
- `NEW_PROJECT_GAME2D_INPUT_CONTRACT_OK`
- `NEW_PROJECT_GATEKEEPER_BOSS_SKILL_OK`
- `NEW_PROJECT_GATEKEEPER_CHARGE_SKILL_OK`
- `VFX_SEPARATION_AND_DIRECTIONAL_FOOTSTEP_FOCUSED_OK`

## 后续建议

1. 生成玩家 4 方向或 8 方向动作条：`idle/run/attack/death` 每个方向一段。
2. 敌人至少先做左右两个方向，Boss 优先做朝下/左右/朝上四方向。
3. 给 `visual_asset_manifest` 增加正式方向字段，例如 `direction_mode = "4dir"`、`direction_frames`。
4. 把 Boss 砸地、冲锋、死亡爆裂继续拆成独立 VFX 层，不画进 Boss 主体动画。
