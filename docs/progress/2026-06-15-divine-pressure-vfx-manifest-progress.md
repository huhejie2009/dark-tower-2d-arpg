# 神罚预警 VFX 资产接口进度

日期：2026-06-15

## 本轮目标

为神罚预警建立 authored VFX 资产接口，让后续美术可以用真实场景/特效资源替换当前临时程序化预警，同时保持当前战斗可读性和测试稳定。

## 完成内容

- `DivinePressureService.build_event_config()` 新增 `vfx_manifest`。
- `vfx_manifest` 固定以下字段：
  - `interface_id: divine_pressure_vfx`
  - `interface_version: 1`
  - `asset_family: cold_megastructure_divine_pressure`
  - `warning_role: enemy_pressure_warning`
  - `impact_role: enemy_pressure_impact`
  - `warning_scene_path`
  - `impact_scene_path`
  - `fallback_programmatic`
  - `authored_asset_required_before_art_lock`
- `Vfx2DFactory` 的神罚预警和冲击节点会携带 manifest metadata。
- `Game2D` 触发神罚时会把 manifest 传给 warning/impact VFX。
- 新增回归：`regression_divine_pressure_vfx_manifest_contract.gd`。

## 当前边界

- 当前仍使用临时程序化预警作为 fallback。
- 尚未接入正式 authored VFX 场景资源。
- 不替换正式美术素材。
- 不新增随机惩罚表。
- 不影响传送门流程。

## 验证

- `NEW_PROJECT_DIVINE_PRESSURE_VFX_MANIFEST_CONTRACT_OK`
- `NEW_PROJECT_DIVINE_PRESSURE_SERVICE_OK`
- `NEW_PROJECT_DIVINE_PRESSURE_GAME2D_CONTRACT_OK`
- `NEW_PROJECT_COMBAT_VFX_SEPARATION_CONTRACT_OK`
- `NEW_PROJECT_FLOOR_CLEAR_PORTAL_OK`
- `NEW_PROJECT_SCENE_BOOT_ALL_OK`

## 下一步建议

下一步可以制作一个 `DivinePressureVfxProfile` 资源或场景挂载方案，用 `warning_scene_path` / `impact_scene_path` 指向真实 authored VFX；在资源未齐前继续保留 fallback。
