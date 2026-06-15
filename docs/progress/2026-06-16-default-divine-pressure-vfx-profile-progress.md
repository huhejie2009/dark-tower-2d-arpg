# 默认神罚 VFX Profile 占位资源进度

日期：2026-06-16

## 本轮目标

建立默认 `.tres` profile 占位资源，让神罚预警 authored VFX 后续可以通过资源路径接入，而不是继续改代码。当前仍保持程序化 fallback，不替换正式效果。

## 完成内容

- 新增默认资源：
  - `res://assets/vfx/divine_pressure/default_divine_pressure_vfx_profile.tres`
- 资源内容：
  - `interface_id = divine_pressure_vfx`
  - `interface_version = 1`
  - `asset_family = cold_megastructure_divine_pressure`
  - `warning_scene_path = ""`
  - `impact_scene_path = ""`
  - `fallback_programmatic = true`
  - `authored_asset_required_before_art_lock = true`
- 新增回归：
  - `regression_default_divine_pressure_vfx_profile.gd`

## 当前边界

- 资源路径为空，表示 authored VFX 尚未接入。
- fallback 开启，当前游戏仍使用临时程序化预警。
- 不替换正式素材。
- 不影响神罚触发、传送门、楼层流程。

## 验证

- `NEW_PROJECT_DEFAULT_DIVINE_PRESSURE_VFX_PROFILE_OK`
- `NEW_PROJECT_DIVINE_PRESSURE_VFX_PROFILE_RESOURCE_OK`
- `NEW_PROJECT_DIVINE_PRESSURE_VFX_MANIFEST_CONTRACT_OK`
- `NEW_PROJECT_DIVINE_PRESSURE_GAME2D_CONTRACT_OK`
- `NEW_PROJECT_SCENE_BOOT_ALL_OK`

## 下一步建议

下一步可以做“authored VFX 场景加载分支”：当 profile 的 `warning_scene_path` / `impact_scene_path` 非空时，优先实例化 authored 场景；否则继续使用程序化 fallback。
