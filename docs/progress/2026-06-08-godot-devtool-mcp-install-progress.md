# 2026-06-08 godot-devtool MCP 安装配置记录

## 来源

- 仓库：`https://github.com/wangdiandao/godot-devtool`
- 文档：`README.zh-CN.md`
- 版本：`3.2.0`

## README 理解摘要

`godot-devtool` 是 Godot 4 的 stdio MCP server，提供：

- native/headless 项目检查与文件、脚本、场景操作。
- editor WebSocket bridge，用于实时编辑器选择、Inspector 写入、UndoRedo、场景保存。
- runtime bridge/autoload，用于运行中场景树、属性、输入模拟、截图、QA 检查。
- Browser visualizer，用于查看 bridge/client 状态。

Codex Desktop 需要在 `C:\Users\huhej\.codex\config.toml` 增加 `[mcp_servers.godot-devtool]`。每个 Godot 项目还需要安装 `addons/godot_devtool`，并注册 runtime autoload。

## 本机安装

release zip 解压后缺少 Node 运行依赖，因此改用源码构建：

- 源码路径：`C:\Users\huhej\.codex\mcp\godot-devtool-source\godot-devtool-main`
- MCP 入口：`C:\Users\huhej\.codex\mcp\godot-devtool-source\godot-devtool-main\build\index.js`
- Node：`E:\New Folder\node.exe`
- Godot ASCII 副本：`C:\Users\huhej\.codex\mcp\godot-bin\Godot_v4.6.2-stable_win64_console.exe`

使用 ASCII 路径是为了避免 MCP/Node/PowerShell 处理中英文桌面路径时出现编码问题。

## Codex 配置

已加入：

```toml
[mcp_servers.godot-devtool]
command = 'E:\New Folder\node.exe'
args = ['C:\Users\huhej\.codex\mcp\godot-devtool-source\godot-devtool-main\build\index.js']
startup_timeout_sec = 120
enabled = true

[mcp_servers.godot-devtool.env]
GODOT_PATH = 'C:\Users\huhej\.codex\mcp\godot-bin\Godot_v4.6.2-stable_win64_console.exe'
GODOT_DEVTOOL_WS_PORT = "8766"
```

需要重启 Codex Desktop 后，新 MCP server 才会作为正式工具出现在会话中。

## 项目配置

已复制插件到：

- `addons/godot_devtool`

已更新 `project.godot`：

- `DevtoolRuntime="*res://addons/godot_devtool/runtime_bridge.gd"`
- `enabled=PackedStringArray("res://addons/godot_ai/plugin.cfg", "res://addons/godot_devtool/plugin.cfg")`

## 验证结果

- TOML 解析：通过。
- MCP stdio 初始化：通过，serverInfo 为 `godot-devtool 3.2.0`。
- `get_godot_version`：返回 `4.6.2.stable.official.71f334935`。
- `plugin_status`：`installed=true`，`runtime.installed=true`，WebSocket 端口 `8766`。
- Godot headless 启动：退出码 `0`。
- 场景烟测：通过。
- 完整回归：`ALL_NEW_PROJECT_REGRESSION_OK COUNT 94`。
- 残留测试进程：`NO_RESIDUAL_GODOT_DEVTOOL_TEST_PROCESS`。

## 注意事项

- 打开 Godot 编辑器后，如插件未显示启用状态，请在 `Project > Project Settings > Plugins > godot-devtool > Enable` 手动确认一次。
- editor/runtime 连接只有在 Godot 编辑器打开或项目运行时才会变为 connected。
- npm install 报告了 3 个依赖审计告警；本轮未执行 `npm audit fix --force`，避免自动升级依赖改变 MCP 行为。
- Godot headless 退出时出现资源仍在使用的警告，但测试退出码为 0，完整回归通过。后续如要追踪，可以用 `--verbose` 单独定位插件/autoload 退出清理。
