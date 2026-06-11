# 2026-06-11 像素角色生产包进度

## 本轮目标

在像素角色试点契约之后，补齐第一批正式素材的生产说明，避免后续 IMAGE2 或美术协作时只靠口头描述。

## 已完成

- 生成并保存像素角色三人组方向预览：
  - `docs/concepts/pixel_actor_trial/pixel_actor_lineup_preview_v1.png`
- 新增正式生产包：
  - `docs/content/2026-06-11-pixel-actor-production-pack.md`
- 生产包覆盖：
  - 玩家战士
  - 腐朽近战怪
  - 暗影弓手
  - 4 向帧条规格
  - 每方向 20 帧动作段
  - IMAGE2 通用提示词
  - 三类角色专用提示词
  - 导入验收清单
- 新增回归：
  - `tests/regression/regression_pixel_actor_production_pack.gd`

## 验证

已运行：

```text
NEW_PROJECT_PIXEL_ACTOR_PRODUCTION_PACK_OK
```

Godot 退出时仍打印已有 `ObjectDB instances leaked` / `resources still in use` 警告，本轮测试退出码为 0。

## 下一步建议

1. 用生产包先制作 `player_warrior_4dir_pixel_sheet_v1.png`。
2. 只接入玩家 4 向素材并截图 QA，不同时替换敌人。
3. 玩家通过后，再制作并接入 `rot_melee` 和 `shadow_archer`。
4. 所有 4 向素材验收后，再把 manifest 的 `direction_mode` 从过渡期 `runtime_flip_2dir` 切换为 `4dir`。
