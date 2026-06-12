# 2026-06-13 动作分离与武器分层进度

## 本轮目标

根据试玩反馈修正像素角色生产管线：不再把多个动作混在一次生成里，也不再把玩家武器烘焙进身体帧。

## 已完成

- 新增正式管线文档：
  - `docs/content/2026-06-13-layered-weapon-action-separated-pipeline.md`
- 更新生产包：
  - `docs/content/2026-06-11-pixel-actor-production-pack.md`
- 玩家默认 manifest 新增：
  - `animation_pipeline: action_separated`
  - `weapon_layer_mode: external_attach`
  - `body_sprites_must_exclude_weapon: true`
  - `smooth_animation_requirements`
  - `weapon_anchor_tracks`
- 玩家节点新增预留插槽：
  - `WeaponSprite`
- 玩家节点新增武器视觉 manifest 测试接口：
  - `apply_weapon_visual_manifest_for_test`
  - `get_weapon_visual_manifest_for_test`
- 新增回归：
  - `tests/regression/regression_layered_weapon_animation_pipeline.gd`

## 当前策略

- 角色身体动画按动作单独生产：`idle`、`run`、`attack`、`death` 分开生成。
- 玩家身体不带武器。
- 武器作为独立素材，通过挂点跟随手部。
- 打击特效继续独立于身体和武器。
- 旧的 4 向混合候选图只作为参考，不进入运行时。

## 验证

已运行：

```text
NEW_PROJECT_LAYERED_WEAPON_ANIMATION_PIPELINE_OK
```

Godot 退出时仍打印已有 `ObjectDB instances leaked` / `resources still in use` 警告，本轮测试退出码为 0。

## 下一步建议

1. 先重新生成 `player_warrior_body_down_idle_v1.png`，不带武器。
2. 通过后再生成 `down_run`，重点检查换脚流畅度。
3. 再生成 `down_attack` 身体动作，并单独制作短剑 weapon sprite。
4. 建立第一版 `weapon_anchor_tracks` 数据，再做测试场景合成。
