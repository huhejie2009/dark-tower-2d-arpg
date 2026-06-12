# 2026-06-13 玩家战士下方向 20 帧候选小条 QA

## 文件

绿幕源图：

```text
docs/concepts/pixel_actor_trial/player_warrior_down_pixel_strip_candidate_v1_green.png
```

透明候选：

```text
assets/generated/actors/candidates/player_warrior_down_pixel_strip_candidate_v1.png
```

## 结论

该图可作为“下方向 20 帧切格/锚点评估候选”，暂不接入实机 manifest。

## 通过项

- 单行 20 帧结构基本成立，比一次生成 4 向 80 帧更可控。
- 透明背景候选已经生成，后续可用脚本切格检查。
- 玩家战士的黑铁盔甲、蓝灰披风、短剑轮廓与项目当前风格接近。
- 动作段可以大致分辨为 `idle`、`run`、`attack`、`death`。
- 攻击动作有明显举剑、挥出、收招意图。

## 风险项

- 像素颗粒仍偏弱，部分区域像缩小后的厚涂角色。
- `run` 的左右脚交替还需要更清楚。
- 站立/奔跑/攻击帧的底部锚点需要进一步切格后确认。
- 死亡段可读，但倒地体积横向变宽，后续碰撞和排序要只使用脚底/身体核心锚点。

## 下一步

1. 对透明候选按 20 等分切格，检查每格有效像素边界。
2. 生成一张 20 帧预览 sheet，标出底部锚线。
3. 如果锚点漂移可接受，再尝试在测试场景中只替换玩家下方向显示。
4. 如果锚点漂移过大，继续调整 IMAGE2 提示词，要求 `same foot baseline and same cell center`。

## 资产状态

```text
status: candidate_cutting_ready
runtime_connected: false
approved_for_manifest_switch: false
candidate_direction: down
candidate_frame_count: 20
```
