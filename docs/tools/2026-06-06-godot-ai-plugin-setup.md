# 2026-06-06 Godot AI MCP 服务器接入说明

## 已接入内容

- 插件名称：`Godot AI`
- 插件版本：`2.4.4`
- 插件定位：Godot 编辑器内 MCP 服务器与 AI 工具桥接
- 项目路径：`res://addons/godot_ai/`
- 插件入口：`res://addons/godot_ai/plugin.cfg`
- 运行时辅助 Autoload：`_mcp_game_helper`
- 默认 HTTP MCP 地址：`http://127.0.0.1:8000/mcp`
- 默认 WebSocket 端口：`9500`

本次接入的是旧项目使用过的 MCP 服务器版 Godot AI，不是普通的编辑器聊天插件，也不是游戏内怪物 AI 系统。

## Codex 侧配置

本机 `C:\Users\huhej\.codex\config.toml` 已存在 Godot AI MCP 配置：

```toml
[mcp_servers."godot-ai"]
url = "http://127.0.0.1:8000/mcp"
enabled = true
```

这表示 Codex 已知道要连接本地 `godot-ai` MCP 服务器。若当前线程启动时服务器还没运行，工具可能不会立刻出现在本线程中，通常需要在 Godot 编辑器启动 MCP 后重新打开或刷新 Codex 线程。

## 启动方式

1. 打开新项目：
   - `H:\GODOT_PROJECT\dark-tower-2d-arpg`
2. 在 Godot 编辑器中确认插件启用：
   - `Project > Project Settings > Plugins > Godot AI`
3. 如插件刚刚接入，请重启或重新载入 Godot 编辑器，让 MCP dock 和服务器管理器完整进入编辑器生命周期。
4. 插件会优先寻找本地开发虚拟环境，其次使用 `uvx` 启动：
   - `uvx --from godot-ai==2.4.4 godot-ai`
5. 本机已检测到 `uv/uvx` 可用，因此无需把 Python 包写入项目目录。

## 验证记录

- 插件配置已确认：
  - `description="MCP server and AI tools for Godot"`
  - `version="2.4.4"`
- 项目已启用：
  - `enabled=PackedStringArray("res://addons/godot_ai/plugin.cfg")`
- Autoload 已注册：
  - `_mcp_game_helper="*res://addons/godot_ai/runtime/game_helper.gd"`
- 回归测试：
  - `res://tests/regression/regression_godot_ai_plugin_enabled.gd`
  - 通过标记：`NEW_PROJECT_GODOT_AI_PLUGIN_ENABLED_OK`

## 注意边界

- 没有清除玩家存档。
- 没有修改存档结构。
- 没有回到旧 3D 项目修场景。
- 没有恢复或接入 POLYGON 资源。
- Godot headless editor 会打印 `MCP | plugin disabled in headless mode`，这是插件设计行为；真正的 MCP 服务器需要普通 Godot 编辑器生命周期启动。
