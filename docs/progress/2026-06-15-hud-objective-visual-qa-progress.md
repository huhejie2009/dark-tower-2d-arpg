# HUD 目标文本视觉 QA 进度

日期：2026-06-15

## 本轮目标

在房间目标系统已经接入 HUD 后，补齐可自动验证的 HUD 视觉 QA 合同，避免目标文本、日志、血条、魔力条、经验条在后续 UI 调整中互相挤压。

## 完成内容

- 扩展 `regression_ui_visual_qa_layout_contract.gd`：
  - 验证主 HUD 面板在 800x600 视口内。
  - 验证目标文本保留可读空间。
  - 验证目标文本不压到生命条。
  - 验证经验条仍在 HUD 面板内。
- 扩展 `HudController.get_visual_qa_rects_for_test()`：
  - 返回 `hud_panel`、`status`、`log`、`objective`、`health_bar`、`mana_bar`、`experience_bar`。
  - 保留原有 `inventory` 和 `loot` 布局 QA 矩形。

## 验证

- `NEW_PROJECT_UI_VISUAL_QA_LAYOUT_CONTRACT_OK`
- `NEW_PROJECT_ROOM_OBJECTIVE_HUD_CONTRACT_OK`
- `NEW_PROJECT_HUD_VITALS_CONTRACT_OK`
- `NEW_PROJECT_HUD_LEVEL_EXPERIENCE_CONTRACT_OK`
- `NEW_PROJECT_SCENE_BOOT_ALL_OK`

## 后续建议

下一步可以继续推进“神罚预警 authored VFX 接口”，把当前临时程序化预警替换为可由美术资产接管的 manifest/接口，但先不更换正式素材。
