extends Control

const SceneRouterScript := preload("res://scripts/app/SceneRouter.gd")
const DarkArpgUiThemeScript := preload("res://scripts/ui/DarkArpgUiTheme.gd")

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.name = "MainMenuDarkBackground"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = DarkArpgUiThemeScript.COLOR_VOID
	add_child(background)

	var panel := PanelContainer.new()
	panel.name = "MainMenuPanel"
	panel.position = Vector2(430, 170)
	panel.size = Vector2(420, 260)
	DarkArpgUiThemeScript.style_panel(panel, true)
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 28)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Dark Tower 2D"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	DarkArpgUiThemeScript.style_title(title, 42)
	box.add_child(title)

	var start := Button.new()
	start.name = "StartButton"
	start.text = "Start Game"
	start.custom_minimum_size = Vector2(280, 54)
	DarkArpgUiThemeScript.style_button(start, true)
	start.pressed.connect(func(): SceneRouterScript.go_to_character_select(get_tree()))
	box.add_child(start)

func get_ui_style_id_for_test() -> String:
	return DarkArpgUiThemeScript.get_style_id()
