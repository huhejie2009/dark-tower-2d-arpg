# 2026-06-17 2.5D 真实贴图 Manifest V1 进度

## 本轮目标

将 2.5D billboard 战斗原型从运行时占位 Manifest 推进到真实素材 Manifest V1。此轮不生成新素材，只复用项目中已经存在的 production sheet，目的是先把“素材接口”和“实机场景加载链路”固定下来。

## 已完成

- 新增 `scripts/prototype/BillboardActorManifestLibrary.gd`。
- 玩家接入 `player_warrior_sheet_v3.png`，帧尺寸为 `160x160`。
- 敌人 1 接入 `enemy_rot_melee_sheet_v3.png`，帧尺寸为 `128x128`。
- 敌人 2 接入 `enemy_shadow_archer_sheet_v3.png`，帧尺寸为 `128x128`。
- 统一 Manifest 字段：
  - `asset_pipeline = image2`
  - `pose_variation_version = production_dark_armor_v3`
  - `texture_filter = nearest`
  - `direction_mode = runtime_flip_2dir`
  - `body_sprites_must_exclude_weapon = true`
  - `combat_vfx_separated = true`
- `BillboardActor3D` 的测试快照新增贴图加载、可见性、素材管线、滤镜和方向模式字段。
- `BillboardActorAnimationProfile` 现在可以输出标准 `visual_asset_manifest`，后续可从资源文件或编辑器表驱动同一条链路。
- `Prototype2_5DCombatRoom` 已不再把玩家和敌人的正常路径指向 `runtime_placeholder`，占位 Manifest 只保留为缺省回退。

## 新增回归

- `tests/regression/regression_billboard_actor_real_texture_manifest.gd`
  - 验证 Manifest 库字段完整。
  - 验证 `BillboardActor3D` 可以加载真实贴图。
  - 验证 idle/run/attack/death 起始帧区间。
- `tests/regression/regression_prototype_2_5d_real_actor_textures.gd`
  - 验证 2.5D 战斗房间中玩家、近战敌人、弓手敌人都使用真实 production sheet。
  - 验证角色 Sprite3D 可见且 texture 已加载。

## 验收标准

- Manifest 测试必须通过，并打印 `NEW_PROJECT_BILLBOARD_ACTOR_REAL_TEXTURE_MANIFEST_OK`。
- 场景接入测试必须通过，并打印 `NEW_PROJECT_PROTOTYPE_2_5D_REAL_ACTOR_TEXTURES_OK`。
- 旧的 2D IMAGE2 玩家/敌人合约测试仍然通过。
- 2.5D 攻击动画状态同步和打击 VFX 分离测试仍然通过。
- 完整回归必须通过。

## 后续建议

1. 基于此 Manifest 库继续补充 boss、守卫、NPC 的 2.5D 显示入口。
2. 将武器贴图层从当前预留 `WeaponSprite` 推进到独立武器 Manifest。
3. 用正式美术素材替换当前 production sheet 时，只替换路径、帧尺寸、动作区间和 fps，不改战斗逻辑。
4. 进行一次实机截图 QA，检查角色比例、地面接触阴影、可读性标记是否需要下调。
