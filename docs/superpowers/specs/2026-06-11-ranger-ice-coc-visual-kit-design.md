# 游侠寒冰 CoC 视觉套装设计规格

日期：2026-06-11  
状态：已确认设计，待实施计划  
适用项目：Dark Tower 2D ARPG

## 1. 目标

当前测试体验仍偏抽象：虽然职业、技能和 CoC 规则已能工作，但玩家很难从画面上区分“游侠”“弓箭”“寒冰射击”和“冰矛触发”。本规格的目标是补齐第一套可测试视觉资产，让游侠寒冰 CoC Build 在实机中具有清晰可读的身份和技能反馈。

第一版目标不是最终商用品质，而是：

- 选游侠进图后能明显区别于战士。
- 攻击动作能看出“持弓/拉弓/射击”。
- 寒冰射击看起来像冰箭。
- CoC 触发冰矛时玩家能看出额外技能被触发。
- 使用现有 manifest 和动画接口，不重写角色动画系统。
- 不引入不明确许可证素材。

## 2. 资产策略

第一版采用程序化生成资源优先：

- 使用脚本生成游侠 SpriteSheet、武器轮廓、箭矢和技能 VFX。
- 所有生成资源进入 `assets/generated/`。
- 不从网络下载未确认许可证的素材。
- 后续可用 Image2 或开源免费素材替换同路径或同 manifest。

这样做的收益：

- 无版权风险。
- 风格与现有暗塔项目统一。
- 生成速度快，便于马上测试。
- 资源尺寸、帧段和接口完全可控。

## 3. 游侠人物 SpriteSheet

新增资源建议路径：

```text
assets/generated/actors/player_ranger_sheet_v1.png
assets/generated/actors/image2_sources/player_ranger_sheet_v1_source.png
docs/concepts/world_art_direction/player_ranger_sheet_v1_preview.png
```

第一版 SpriteSheet 沿用现有 20 帧横向帧条约定：

| 动画 | 帧段 | 帧数 | 说明 |
| --- | ---: | ---: | --- |
| `idle` | 0-3 | 4 | 持弓待机、轻微呼吸 |
| `run` | 4-9 | 6 | 轻甲跑动，弓随身体摆动 |
| `attack` | 10-15 | 6 | 拉弓、蓄力、释放 |
| `death` | 16-19 | 4 | 倒地或跪倒 |

帧尺寸：

- 宽高：`160x160`。
- 横向总尺寸：`3200x160`。
- 方向模式：`runtime_flip_2dir`。
- 背景：透明。

视觉风格：

- 暗色轻甲。
- 兜帽或短披肩。
- 细长弓轮廓清楚。
- 少量蓝白冰霜点缀。
- 体型与战士重甲明显不同。

## 4. 玩家 Manifest 接入

`Game2D` 应根据 `player_data.base_class` 选择玩家默认 manifest：

| 职业 | Manifest |
| --- | --- |
| `warrior` | 现有 `player_warrior_sheet_v3.png` |
| `ranger` | 新增 `player_ranger_sheet_v1.png` |
| `mage` | 暂时使用程序化占位 |
| `acolyte` | 暂时使用程序化占位 |

新增游侠 manifest：

```gdscript
{
	"asset_pipeline": "generated",
	"pose_variation_version": "ranger_ice_coc_v1",
	"direction_mode": "runtime_flip_2dir",
	"enabled": true,
	"sprite_sheet_path": "res://assets/generated/actors/player_ranger_sheet_v1.png",
	"frame_size": Vector2i(160, 160),
	"hide_procedural_body": true,
	"animations": {
		"idle": {"from": 0, "to": 3, "fps": 6},
		"run": {"from": 4, "to": 9, "fps": 9},
		"attack": {"from": 10, "to": 15, "fps": 12},
		"death": {"from": 16, "to": 19, "fps": 6},
	},
}
```

## 5. 弓、箭矢与技能 VFX

第一版不单独做复杂装备换装。弓包含在游侠 SpriteSheet 中，同时技能 VFX 提供射击反馈。

### 5.1 寒冰射击

`ranger_ice_shot` 使用专用冰箭轨迹：

- 颜色：蓝白、浅青。
- 形状：较宽箭矢，带短尾迹。
- 起点：玩家面前。
- 终点：命中目标或技能射程上限。
- 命中：生成小型冰花和碎片。

表现目标：

- 一眼能看出这是冰属性弓箭攻击。
- 不再像普通白线或近战斩击。

### 5.2 冰矛

`ice_lance` 使用更细、更亮、更长的冰矛轨迹：

- 颜色：更亮的蓝白。
- 形状：细长尖刺。
- 起点：玩家附近或攻击方向前方。
- 命中：更锐利的冰晶爆点。
- 与寒冰射击区分：冰矛更细、更亮、更短促。

### 5.3 CoC 触发提示

当寒冰射击暴击并触发冰矛时，增加短暂触发提示：

- 玩家周围出现小型蓝白闪光。
- 或在冰矛起点出现 0.12 秒触发星芒。

提示只属于表现层，不影响战斗结果。

## 6. 技术接入

保持现有架构边界：

- `SkillRules` 继续定义技能标签、风格和技能 ID。
- `Skill2DLibrary` 根据技能 ID 或标签选择 VFX。
- `Vfx2DFactory` 负责创建具体表现节点。
- `Game2D` 只负责根据职业应用默认玩家 manifest。
- 不把 Build 规则塞进视觉层。

建议新增或扩展：

```text
scripts/combat/Vfx2DFactory.gd
  spawn_ice_arrow_trail()
  spawn_ice_lance_trail()
  spawn_coc_trigger_flash()

scripts/app/Game2D.gd
  _build_player_visual_manifest()
  _apply_default_player_art()

tools/generate_ranger_visual_kit.gd 或 scripts/tools/generate_ranger_visual_kit.gd
  生成 ranger spritesheet 和预览图
```

生成脚本应可重复运行，避免手工资产不可复现。

## 7. 非目标

第一版不做：

- 完整换装系统。
- 每件武器独立贴图。
- 四方向或八方向 SpriteSheet。
- 真实飞行弹体物理。
- 复杂粒子系统。
- 法师和侍僧正式素材。
- 从网络下载素材。

## 8. 验收标准

功能验收：

- 创建/选择游侠并进入战斗后，玩家使用游侠 SpriteSheet。
- 战士仍使用现有战士 SpriteSheet。
- 法师和侍僧不错误套用战士或游侠 SpriteSheet。
- 游侠 `idle/run/attack/death` 动画帧段可播放。
- 游侠攻击动画中能看出拉弓动作。
- `ranger_ice_shot` 生成冰箭轨迹和冰霜命中特效。
- `ice_lance` 生成区别于冰箭的冰矛轨迹。
- CoC 触发时有可见触发提示。

技术验收：

- 生成资源在 `assets/generated/`。
- 资源路径稳定，不写入真实玩家存档。
- 新增测试覆盖职业 manifest 选择。
- 新增测试覆盖寒冰射击、冰矛和触发提示 VFX。
- 战士默认素材合同测试仍通过。
- 游侠 CoC 现有回归仍通过。
- 场景启动测试仍通过。

视觉验收：

- 1080p 下游侠角色可辨认。
- 弓轮廓可辨认。
- 冰箭和冰矛颜色、长度、粗细有差异。
- 特效不遮挡敌人和掉落物。
- 多次攻击不会造成明显残留或过亮。

## 9. 实施顺序建议

1. 编写资产生成脚本，生成游侠 20 帧 SpriteSheet。
2. 新增游侠 manifest 选择逻辑。
3. 新增/更新职业视觉回归测试。
4. 扩展 VFX 工厂，增加冰箭、冰矛和触发闪光。
5. 让 `Skill2DLibrary` 按技能 ID 或标签选择专用 VFX。
6. 运行相关回归和场景烟测。
7. 更新进度文档并提交。

## 10. 风险与控制

| 风险 | 控制 |
| --- | --- |
| 程序化人物不够精美 | 第一版只要求清晰可测，后续可替换同 manifest |
| 特效太亮影响阅读 | 限制透明度、持续时间和尺寸 |
| 资产生成脚本污染工程 | 输出固定路径，生成逻辑独立，不进入运行时 |
| 非战士职业仍套错素材 | 增加职业 manifest 选择测试 |
| 冰箭和冰矛难区分 | 在长度、粗细、颜色亮度上拉开差异 |

