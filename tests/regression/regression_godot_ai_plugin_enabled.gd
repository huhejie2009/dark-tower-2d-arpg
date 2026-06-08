extends SceneTree

const PLUGIN_CFG := "res://addons/godot_ai/plugin.cfg"
const PLUGIN_SCRIPT := "res://addons/godot_ai/plugin.gd"
const GAME_HELPER := "res://addons/godot_ai/runtime/game_helper.gd"
const CLIENT_CONFIGURATOR := "res://addons/godot_ai/client_configurator.gd"
const CODEX_CLIENT := "res://addons/godot_ai/clients/codex.gd"

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_expect(FileAccess.file_exists(PLUGIN_CFG), "Godot AI plugin.cfg should exist")
	_expect(FileAccess.file_exists(PLUGIN_SCRIPT), "Godot AI plugin script should exist")
	_expect(FileAccess.file_exists(GAME_HELPER), "Godot AI MCP game helper autoload script should exist")
	_expect(FileAccess.file_exists(CLIENT_CONFIGURATOR), "Godot AI MCP client configurator should exist")
	_expect(FileAccess.file_exists(CODEX_CLIENT), "Godot AI MCP Codex client config should exist")
	_expect(_plugin_cfg_contains("description=\"MCP server and AI tools for Godot\""), "Godot AI plugin should be the MCP server build")
	_expect(_plugin_cfg_contains("version=\"2.4.4\""), "Godot AI MCP plugin version should match the imported old-project version")
	var script := load(PLUGIN_SCRIPT)
	_expect(script != null, "Godot AI plugin script should load")
	var enabled_plugins: PackedStringArray = ProjectSettings.get_setting("editor_plugins/enabled", PackedStringArray())
	_expect(enabled_plugins.has(PLUGIN_CFG), "Godot AI plugin should be enabled in project settings")
	_expect(ProjectSettings.get_setting("autoload/_mcp_game_helper", "") == "*" + GAME_HELPER, "Godot AI MCP game helper should be registered as an autoload")
	_finish()

func _plugin_cfg_contains(text: String) -> bool:
	var file := FileAccess.open(PLUGIN_CFG, FileAccess.READ)
	if file == null:
		return false
	var content := file.get_as_text()
	return content.contains(text)

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_GODOT_AI_PLUGIN_ENABLED_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
