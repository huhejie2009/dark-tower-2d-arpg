# 2026-06-08 ROADMAP 中文问号修复记录

## 问题

最新 ROADMAP 中部分 P2 更新文本显示为问号，主要出现在：

- `总览` sheet 的 P2 阶段验收/产出描述
- `阶段路线图` sheet 的 P2 验收描述
- `任务工作表` sheet 的 T-009 更新内容
- `验证命令` sheet 最近追加的 P2 聚焦回归命令

## 根因

后几次更新 Excel 时，通过 PowerShell here-string 把中文文本传给 Python/openpyxl。该路径在当前终端环境下会把部分中文降级为 `?`，Python 收到的字符串已经损坏，因此写入 Excel 后显示为问号。

这不是 Godot 项目数据、玩家存档或游戏逻辑问题。

## 已完成修复

- 新增修复脚本：
  - `tools/repair_latest_roadmap_cn.py`
- 生成修复版 ROADMAP：
  - `docs/planning/2026-06-08-dark-tower-2d-arpg-production-roadmap-updated-p2-skill-node-growth-cn-fixed.xlsx`
- 修复内容：
  - P2 总览验收描述
  - P2 阶段路线图验收描述
  - T-009 任务名、状态、验收标准、验证命令
  - P2 聚焦回归命令中的中文标题和 Godot 路径 `桌面`

## 验证结果

已读取修复后的 xlsx 并检查所有 sheet：

- P2 总览验收为中文
- P2 阶段路线图验收为中文
- T-009 为中文
- P2 验证命令为中文
- `BAD_CELLS []`

## 后续约束

后续更新 Excel 时，不再把大段中文直接放进 PowerShell here-string 写入。优先使用 UTF-8 `.py` 文件或从 UTF-8 文档读取文本，避免再次出现问号。
