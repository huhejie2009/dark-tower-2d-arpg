# 2026-06-11 像素角色美术试点进度

## 本轮目标

按“小范围试点”方案推进：不大改功能，只把玩家、近战小怪、远程小怪纳入暗黑高分辨率像素角色管线，为后续正式素材替换留接口。

## 已完成

- 新增像素角色试点回归：`tests/regression/regression_pixel_actor_art_trial_contract.gd`
- 玩家默认 manifest 新增：
  - `art_family`
  - `environment_pairing`
  - `texture_filter`
  - `directional_target`
  - `separate_combat_vfx`
  - `contact_shadow`
- `rot_melee` 与 `shadow_archer` 默认 manifest 新增同样美术契约字段。
- `Player2D` 与 `Enemy2D` 支持按 manifest 设置 `ActorSprite.texture_filter`，像素素材使用 nearest。
- 新增协作文档：`docs/content/2026-06-11-pixel-actor-art-trial-pipeline.md`
- 新增执行计划：`docs/superpowers/plans/2026-06-11-pixel-actor-art-trial.md`

## 当前设计判断

场景继续走冷峻厚涂/半写实，角色转为高分辨率暗黑像素是可行路线。关键不是“像素化”本身，而是像素角色必须低饱和、体块明确、带接触阴影，并与环境共用冷色暗部。

## 后续建议

1. 先生成或制作 `player_warrior_4dir_pixel_sheet_v1.png` 的单角色 4 向素材。
2. 通过同一规格制作 `rot_melee` 和 `shadow_archer`。
3. 素材稳定后，再把 `direction_mode` 从 `runtime_flip_2dir` 切到 `4dir`。
4. Boss 和主城 NPC 等待试点验收后再迁移。
