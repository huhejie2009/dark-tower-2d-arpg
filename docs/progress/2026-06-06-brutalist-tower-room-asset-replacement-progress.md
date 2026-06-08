# 2026-06-06 冷峻巨构塔内厅场景素材替换进度

## 本次目标

把战斗场景从偏梦幻/华丽/中式室内背景，替换为符合已确认世界观效果图的冷峻巨构塔内部风格。

游戏内仍保持生产友好的顶视/轻俯视 2D，不回到斜 45 度梦幻西游式视角，方便后续使用 IMAGE2 继续制作人物、怪物、Boss 和动作帧素材。

## 已完成

- 新增实现计划：
  - `docs/superpowers/plans/2026-06-06-brutalist-tower-room-asset-replacement.md`
- 新增环境素材：
  - `res://assets/generated/environments/tower_interior_brutalist_room_v1.png`
  - `res://assets/generated/environments/tower_interior_brutalist_room_v1.png.import`
- `Game2D.gd` 环境背景路径已切换到新塔内厅素材。
- `Game2D.gd` 新增视觉契约字段：
  - `ENVIRONMENT_FAMILY = "brutalist_tower_interior"`
  - `WORLD_ART_ANCHOR = "cold_megastructure_dark_core"`
  - `FORBIDDEN_STYLE = "mhxy_ornate_palace"`
- 场景层级语义从旧 `mhxy` 室内方向改为巨构塔内厅方向：
  - `TopDownDarkCoreLightChannel`
  - `TopDownDarkCoreGlow`
  - `TopDownSideLightChannel`
- 保留原有可玩规则：
  - 顶视生产视角
  - 角色脚底锚点排序
  - 柱子和高障碍物只使用脚印碰撞
  - 不用整张柱子图当移动阻挡
- 更新回归测试，明确禁止旧风格方向重新变成默认：
  - `regression_image2_environment_background_contract.gd`
  - `regression_topdown_production_view_contract.gd`

## 素材方向

本次游戏内背景抽取了确认效果图中的核心气质：

- 宽大、冷灰、压迫的水泥巨构。
- 暗蓝色竖向核心光条。
- 荒冷、克制、低饱和度。
- 中央区域保持干净，优先服务战斗读图。

本次没有采用：

- 中式宫殿/屋顶/红木栏杆。
- 暖色灯笼、蜡烛和金色装饰。
- 斜 45 度高透视。
- 复杂华丽装饰堆叠。

## 验证结果

- Godot 导入新素材：`EDITOR_IMPORT_EXIT 0`
- 场景烟测：
  - `NEW_PROJECT_SCENE_BOOT_ALL_OK`
- 专项测试：
  - `NEW_PROJECT_IMAGE2_ENVIRONMENT_BACKGROUND_CONTRACT_OK`
  - `NEW_PROJECT_TOPDOWN_PRODUCTION_VIEW_CONTRACT_OK`
- 完整回归：
  - `ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动：
  - `MAIN_HEADLESS_EXIT 0`

## 边界

- 没有清除玩家存档。
- 没有修改存档结构。
- 没有回到旧 3D 项目。
- 没有恢复或接入 POLYGON 资源。
- 旧 `mhxy_isometric_room_bg_v1.png` 暂时保留在目录中，但 `Game2D.gd` 已不再引用它。

## 下一步建议

1. 进入 Godot 实机试玩新战斗房间，看角色、敌人和 HUD 在新背景上的可读性。
2. 继续用 IMAGE2 按新风格重做玩家与怪物动作帧，避免与冷峻塔内厅风格冲突。
3. 后续再把旧测试/函数名里残留的 `pseudo_34` 逐步迁移为 `topdown`，但不急于一次性大重命名。
