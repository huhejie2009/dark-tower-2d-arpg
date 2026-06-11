# 2026-06-11 像素角色美术试点管线

## 目标

本试点用于验证“场景保持厚涂/半写实，人物与怪物改为暗黑高分辨率像素角色”的可行性。试点范围只覆盖玩家、腐朽近战怪、暗影弓手，不扩展到 Boss 和主城 NPC。

## 风格边界

- 场景：继续使用冷峻、低饱和、厚涂或半写实的通天塔石材环境。
- 角色：使用高分辨率像素角色，不做 Q 版，不做高饱和可爱像素。
- 统一方式：角色必须带接触阴影、冷色调、低亮度轮廓光，并匹配场景的暗部对比。
- 特效：打击特效与角色动画分离。角色动作只负责身体、武器、死亡姿态；命中火花、挥砍轨迹、投射物、地面警示由 VFX 层负责。

## 当前试点 manifest 字段

玩家、`rot_melee`、`shadow_archer` 需要声明：

```gdscript
"art_family": "dark_high_res_pixel_actor",
"environment_pairing": "painterly_brutalist_tower",
"texture_filter": "nearest",
"directional_target": "4dir",
"separate_combat_vfx": true,
"contact_shadow": {
	"required": true,
	"style": "soft_grounded_cold_ambient",
},
```

这些字段是给美术、程序和回归测试共同使用的协作契约。功能开发只需要继续调用现有 `apply_visual_asset_manifest()`，不应该直接关心素材文件的绘制方式。

## 第一批正式素材规格

- 玩家：`player_warrior_4dir_pixel_sheet_v1.png`
- 近战怪：`enemy_rot_melee_4dir_pixel_sheet_v1.png`
- 远程怪：`enemy_shadow_archer_4dir_pixel_sheet_v1.png`
- 每方向 20 帧：`idle 0-3`、`run 4-9`、`attack 10-15`、`death 16-19`
- 方向顺序：`down`、`left`、`right`、`up`
- 角色锚点：底部中心，脚底接触点稳定
- 背景：透明背景，不带地面、不带 UI、不带文字
- Godot 过滤：nearest

## 与 co-worker 的协作边界

- 美术试点主要修改 `assets/generated/actors/`、`scripts/app/Game2D.gd` 的默认玩家 manifest、`scripts/rules/FloorRules.gd` 的敌人 manifest、`docs/content/` 和回归测试。
- co-worker 可以继续开发背包、装备、商人、仓库、楼层、存档等功能，只要不删除 `apply_visual_asset_manifest()` 接口即可。
- 如果功能侧新增敌人类型，只需要先复制当前 manifest 字段，正式素材完成后替换 `sprite_sheet_path` 和 `frame_size`。
- 不清理玩家存档，不回退现有场景，不恢复旧 3D/POLYGON 资源。

## 验收标准

- 打开战斗场景后，玩家与试点敌人的图片素材继续正常加载。
- 玩家与试点敌人的 `ActorSprite.texture_filter` 为 nearest。
- `rot_melee` 和 `shadow_archer` manifest 都声明像素角色美术家族。
- `directional_target` 已标记为 `4dir`，但当前仍允许使用 `runtime_flip_2dir` 过渡素材。
- 回归测试 `regression_pixel_actor_art_trial_contract.gd` 通过。
