# 2026-06-17 2.5D 视觉接地 QA 进度

## 本轮目标

在不新增美术素材的前提下，让 2.5D billboard 角色在实机灰盒场景中更“站在地面上”，并避免彩色调试标记破坏正常画面阅读。

## 已完成

- `BillboardActor3D` 新增 `ContactShadow` 节点。
- `BillboardActorManifestLibrary` 为玩家、腐化近战敌人、暗影弓手补充 `contact_shadow` 参数：
  - `required`
  - `style`
  - `radius`
  - `depth`
  - `alpha`
- `BillboardActor3D.apply_visual_asset_manifest()` 会消费 `contact_shadow` 字段，控制接地阴影可见性、比例和透明度。
- `Prototype2_5DCombatRoom` 的彩色可读性标记现在默认隐藏，避免正常画面被调试圆柱覆盖。
- 保留调试标记节点和测试开关：
  - `set_debug_readability_markers_enabled_for_test(true)`
  - `set_debug_readability_markers_enabled_for_test(false)`
- 新增 `build_visual_grounding_snapshot_for_test()`，用于回归检查：
  - 角色数量
  - 接地阴影数量
  - 可见接地阴影数量
  - 平均阴影透明度
  - 调试标记数量
  - 调试标记可见数量

## 新增回归

- `tests/regression/regression_prototype_2_5d_visual_grounding_contract.gd`

验收内容：

- 玩家和两个敌人都有接地阴影。
- 接地阴影默认可见。
- 调试可读性标记节点仍然存在。
- 调试标记默认隐藏。
- 测试开关可以打开并再次关闭调试标记。

## 设计说明

本轮没有生成新图片资源。接地阴影是运行时渲染辅助节点，用来解决角色贴图“漂浮”和“与地面割裂”的早期观感问题。后续正式素材接入时，这个接口仍然保留，可由 Manifest 调整阴影半径、深度和透明度。

## 后续建议

1. 做一次实机截图 QA，检查角色比例、阴影深浅、遮挡关系和地面阅读性。
2. 将 `ContactShadow` 参数扩展到 boss、守卫和 NPC Manifest。
3. 下一轮可以推进独立武器层 Manifest，让角色身体动画继续保持不烘焙武器。
