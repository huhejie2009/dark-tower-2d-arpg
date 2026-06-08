# 2026-06-05 伪 3/4 俯视视角进度

## 本轮目标

根据确认后的 C 方案，将战斗场景第一版改成伪 3/4 俯视观感。目标是提升房间立体感、角色存在感和弹幕可读性，同时保持现有纯 2D 玩法逻辑稳定。

## 已完成

- 新增正式设计规格：
  - `docs/superpowers/specs/2026-06-05-pseudo-34-camera-design.md`
- 新增实施计划：
  - `docs/superpowers/plans/2026-06-05-pseudo-34-camera-plan.md`
- `Game2D.gd`：
  - 新增 `ROOM_VISUAL_MODE = "pseudo_34"`。
  - Camera2D 缩放调整为更近的伪 3/4 战斗视角。
  - 新增 `Pseudo34Floor` 房间表现根节点。
  - 新增轻微斜切地板、多边形房间边框、压缩地砖线和程序化障碍表现。
  - 保持 `room_rect` 和玩家移动 clamp 不变。
  - 新增 `_get_visual_style_for_test()` 作为视觉契约测试入口。
- `Player2D.gd`：
  - 新增 `PlayerShadow` 脚底阴影。
  - 新增 `PlayerFacingHint` 朝向提示。
  - 将玩家程序化外观改为更高、更像伪 3/4 角色的多边形。
- `Enemy2D.gd`：
  - 新增 `EnemyShadow` 脚底阴影。
  - 将敌人程序化外观改为更高的多边形身体。
  - 保留血条、名字板、精英/Boss 标识逻辑。
- 新增回归测试：
  - `tests/regression/regression_pseudo_34_visual_contract.gd`

## 验证结果

- 单项回归：`NEW_PROJECT_PSEUDO_34_VISUAL_CONTRACT_OK`
- 完整回归：`ALL_NEW_PROJECT_REGRESSION_OK`
- 主项目 headless 启动：`HEADLESS_EXIT 0`
- Godot 测试残留进程检查：未列出残留 `Godot_v4.6.2-stable_win64` 进程

## 未触碰内容

- 未清除玩家存档。
- 未改动存档 schema。
- 未改动背包、装备、楼层奖励数据结构。
- 未把项目改成 3D。
- 未恢复旧 3D 项目资源。
- 未恢复 POLYGON 资源。

## 当前限制

- 第一版伪 3/4 仍是程序化美术表现，不是正式像素美术。
- 房间障碍当前只做视觉表现，不参与碰撞。
- 投射物、Boss 范围警示和死亡爆炸圈仍按真实 2D 平面显示，优先保证战斗可读性。

## 下一步建议

1. 为房间加入门、墙体厚度和可读的入口/出口方向。
2. 将部分视觉障碍升级为真实碰撞障碍，并补怪物寻路或绕行保护。
3. 给玩家、敌人、投射物和掉落补统一像素风/低分辨率风格资源。
4. 加一轮人工试玩清单，专门检查伪 3/4 视角下的瞄准、贴墙、拾取和传送门读图体验。
