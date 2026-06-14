# 神罚 VFX Profile 资源接口进度

日期：2026-06-15

## 本轮目标

在已有 `vfx_manifest` 合同基础上，新增可由美术/关卡资源挂载的 `DivinePressureVfxProfile` 资源脚本。它用于承载神罚预警和冲击的 authored 场景路径，同时保留临时程序化 fallback。

## 完成内容

- 新增 `scripts/data/DivinePressureVfxProfile.gd`：
  - 继承 `Resource`。
  - 导出 `warning_scene_path` 和 `impact_scene_path`。
  - 提供 `to_manifest()`。
  - 提供 `get_validation_report()`。
  - 提供 `is_authored_ready()`。
- `DivinePressureService.build_vfx_manifest()` 支持传入 profile：
  - 无 profile 时返回默认 fallback manifest。
  - 有 profile 时从 profile 生成 manifest。
- 新增回归：`regression_divine_pressure_vfx_profile_resource.gd`。
- 修复 headless 下 class_name 编译顺序不稳定问题：
  - `DivinePressureService` 显式 preload `DivinePressureVfxProfile.gd`。

## 当前边界

- 未接入真实 authored VFX 场景。
- 未替换当前程序化预警。
- 未新增神罚随机惩罚表。
- 未影响楼层传送门流程。

## 验证

- `NEW_PROJECT_DIVINE_PRESSURE_VFX_PROFILE_RESOURCE_OK`
- `NEW_PROJECT_DIVINE_PRESSURE_VFX_MANIFEST_CONTRACT_OK`
- `NEW_PROJECT_DIVINE_PRESSURE_SERVICE_OK`
- `NEW_PROJECT_DIVINE_PRESSURE_GAME2D_CONTRACT_OK`
- `NEW_PROJECT_SCENE_BOOT_ALL_OK`

## 后续建议

下一步可以建立默认 `.tres` profile 资源占位，路径先为空、fallback 保持开启；等 authored VFX 场景素材完成后，再把 `warning_scene_path` 和 `impact_scene_path` 指向真实场景。
