extends Control

const SceneRouterScript := preload("res://scripts/app/SceneRouter.gd")

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var title := Label.new()
	title.text = "Dark Tower 2D"
	title.position = Vector2(470, 190)
	title.add_theme_font_size_override("font_size", 42)
	add_child(title)

	var start := Button.new()
	start.name = "StartButton"
	start.text = "开始游戏"
	start.position = Vector2(520, 310)
	start.size = Vector2(240, 54)
	start.pressed.connect(func(): SceneRouterScript.go_to_character_select(get_tree()))
	add_child(start)
