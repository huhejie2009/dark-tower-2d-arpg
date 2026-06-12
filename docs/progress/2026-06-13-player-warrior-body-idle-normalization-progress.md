# 玩家战士 Body Idle 归一化进度

日期：2026-06-13

## 本轮完成

- 新增 body-only idle 候选归一化工具。
- 将原始 8 帧候选重排为统一 `192x320` 透明帧格。
- 使用 bottom-center 锚点将脚底线稳定到 `anchor_y=288`。
- 输出归一化帧条、baseline 预览图和 metrics JSON。
- 为归一化结果新增回归测试，锁定帧数、帧尺寸、脚底漂移、中心漂移和“未接入正式运行时”的状态。

## 结果

- max_foot_baseline_drift_px: 0
- max_center_drift_px: 0.5
- runtime_connected: false
- approved_for_manifest_switch: false

## 资产管线结论

归一化这一步是必要的。原始生成帧条虽然脚底线基本稳定，但每格角色横向中心漂移明显，直接进入游戏会造成站立动画“左右滑”。归一化后可以作为后续动作分层制作的标准样例。

## 下一步

1. 做隔离角色预览场景，播放 normalized idle，不替换正式玩家。
2. 继续制作 body-only down run，要求腿部换脚清楚。
3. 建立武器独立层 socket 数据格式，后续攻击动作由身体动作、武器层、打击特效三部分组合。
