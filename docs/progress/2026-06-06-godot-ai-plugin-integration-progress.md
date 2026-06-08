# 2026-06-06 Godot AI MCP 接入进度

## 本次目标

在新 2D 暗黑刷宝/爬塔 ARPG 项目中接入旧项目曾使用过的 Godot AI MCP 服务器插件，方便后续 Codex 通过 MCP 读取 Godot 编辑器状态、检查场景、辅助脚本修改与验证。

## 已完成

- 已纠正此前误接的普通编辑器 AI 插件方向。
- 已从旧项目复制 MCP 服务器版 Godot AI addon：
  - 源项目：`H:\GODOT_PROJECT\godot-2-5-3d-ai-ai\addons\godot_ai`
  - 新项目：`H:\GODOT_PROJECT\dark-tower-2d-arpg\addons\godot_ai`
- 已确认插件版本：
  - `Godot AI 2.4.4`
  - `MCP server and AI tools for Godot`
- 已在 `project.godot` 启用编辑器插件：
  - `res://addons/godot_ai/plugin.cfg`
- 已注册运行时辅助 Autoload：
  - `_mcp_game_helper`
- 已新增并更新 MCP 版本回归测试：
  - `res://tests/regression/regression_godot_ai_plugin_enabled.gd`
- 已确认本机 Codex 配置存在：
  - `http://127.0.0.1:8000/mcp`
- 已确认本机 `uv/uvx` 可用，可由插件拉起 `godot-ai==2.4.4` 服务。
- 已给 Godot AI 日志脚本补充显式 backtrace 依赖，降低首次导入时 class_name 缓存未建立导致的解析报错风险。

## 当前状态

项目侧 MCP 插件文件、Godot 配置、Autoload 和 Codex 配置已对齐。

当前 `http://127.0.0.1:8000/mcp` 未响应，说明普通 Godot 编辑器中的 MCP 服务器尚未处于可连接状态。需要重启或重新载入 Godot 编辑器后，由插件在编辑器生命周期中启动服务器。headless editor 模式不会启动 MCP server，这是插件设计行为。

## 已验证

- Godot AI MCP 插件配置存在。
- Godot AI MCP 插件脚本可加载。
- Godot 项目设置中已启用插件。
- Godot 项目设置中已注册 `_mcp_game_helper` Autoload。
- `uv/uvx` 已安装并可执行。

## 未触碰内容

- 没有清除玩家存档。
- 没有修改存档结构。
- 没有回到旧 3D 项目。
- 没有恢复或接入 POLYGON 资源。

## 下一步建议

1. 重启或重新载入 Godot 编辑器，让 `Godot AI` 插件启动 MCP server。
2. 确认 `127.0.0.1:8000/mcp` 可访问。
3. 如 Codex 当前线程仍看不到 `godot-ai` 工具，重新打开 Codex 线程或刷新工具会话。
4. MCP 工具可用后，继续推进新项目的场景素材替换、玩法 UI 和稳定性检查。
