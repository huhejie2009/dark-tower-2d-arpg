extends Control

const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")
const SceneRouterScript := preload("res://scripts/app/SceneRouter.gd")
const InventoryEquipmentWindowScript := preload("res://scripts/ui/InventoryEquipmentWindow.gd")
const TowerRunStartServiceScript := preload("res://scripts/data/TowerRunStartService.gd")
const TownPrepSummaryServiceScript := preload("res://scripts/data/TownPrepSummaryService.gd")

var player_data: Dictionary = {}
var summary: Label
var character_summary: Label
var progress_summary: Label
var resource_summary: Label
var growth_summary: Label
var start_summary: Label
var prep_recommendations: Label
var inventory_window: Control

func _ready() -> void:
	player_data = SaveManagerScript.get_active_player_data()
	_build_ui()
	_create_inventory_window()

func _build_ui() -> void:
	var title := Label.new()
	title.text = "Tower Approach"
	title.position = Vector2(460, 52)
	title.add_theme_font_size_override("font_size", 34)
	add_child(title)

	summary = Label.new()
	summary.name = "TownSummary"
	summary.position = Vector2(390, 112)
	summary.size = Vector2(500, 42)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_font_size_override("font_size", 18)
	add_child(summary)

	_create_prep_panel()

	var enter := Button.new()
	enter.name = "EnterTowerButton"
	var start_options := TowerRunStartServiceScript.build_start_options(player_data)
	enter.text = str(start_options.get("fresh_label", "Enter Tower: Floor 1"))
	enter.position = Vector2(500, 500)
	enter.size = Vector2(280, 54)
	enter.pressed.connect(_enter_fresh_tower_run)
	add_child(enter)

	var best_floor := Button.new()
	best_floor.name = "EnterBestFloorButton"
	best_floor.text = str(start_options.get("best_label", "Challenge Best Floor"))
	best_floor.position = Vector2(500, 562)
	best_floor.size = Vector2(280, 44)
	best_floor.pressed.connect(_enter_best_floor_run)
	add_child(best_floor)

	var inventory := Button.new()
	inventory.name = "OpenInventoryButton"
	inventory.text = "Inventory / Equipment"
	inventory.position = Vector2(500, 618)
	inventory.size = Vector2(280, 48)
	inventory.pressed.connect(_toggle_inventory_window)
	add_child(inventory)

	var menu := Button.new()
	menu.name = "ReturnMainMenuButton"
	menu.text = "Main Menu"
	menu.position = Vector2(500, 676)
	menu.size = Vector2(280, 48)
	menu.pressed.connect(func(): SceneRouterScript.go_to_main_menu(get_tree()))
	add_child(menu)
	_update_summary()

func _create_prep_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "TownPrepPanel"
	panel.position = Vector2(360, 162)
	panel.size = Vector2(560, 306)
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var panel_title := Label.new()
	panel_title.text = "Preparation"
	panel_title.add_theme_font_size_override("font_size", 20)
	box.add_child(panel_title)

	character_summary = _make_prep_label("TownCharacterSummary")
	box.add_child(character_summary)
	progress_summary = _make_prep_label("TownProgressSummary")
	box.add_child(progress_summary)
	resource_summary = _make_prep_label("TownResourceSummary")
	box.add_child(resource_summary)
	growth_summary = _make_prep_label("TownGrowthSummary")
	box.add_child(growth_summary)
	start_summary = _make_prep_label("TownStartSummary")
	start_summary.custom_minimum_size = Vector2(520, 46)
	box.add_child(start_summary)
	prep_recommendations = _make_prep_label("TownPrepRecommendations")
	prep_recommendations.custom_minimum_size = Vector2(520, 62)
	box.add_child(prep_recommendations)

func _make_prep_label(label_name: String) -> Label:
	var label := Label.new()
	label.name = label_name
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(520, 24)
	label.add_theme_font_size_override("font_size", 15)
	return label

func _create_inventory_window() -> void:
	inventory_window = InventoryEquipmentWindowScript.new()
	add_child(inventory_window)
	inventory_window.set_player_data(player_data)
	inventory_window.player_data_changed.connect(_on_player_data_changed)
	inventory_window.close_requested.connect(func(): inventory_window.visible = false)

func _toggle_inventory_window() -> void:
	inventory_window.visible = not inventory_window.visible
	if inventory_window.visible:
		inventory_window.set_player_data(player_data)

func _enter_fresh_tower_run() -> void:
	TowerRunStartServiceScript.request_fresh_run()
	SceneRouterScript.go_to_game(get_tree())

func _enter_best_floor_run() -> void:
	TowerRunStartServiceScript.request_best_floor(player_data)
	SceneRouterScript.go_to_game(get_tree())

func _on_player_data_changed(updated: Dictionary) -> void:
	player_data = updated.duplicate(true)
	SaveManagerScript.save_active_player_data(player_data, int(player_data.get("highest_floor", 1)))
	_update_summary()

func _update_summary() -> void:
	var prep := TownPrepSummaryServiceScript.build_summary(player_data)
	if is_instance_valid(summary):
		summary.text = "%s | Best Floor %d" % [
		str(player_data.get("character_name", "Hero")),
		int(player_data.get("highest_floor", 1)),
	]
	if is_instance_valid(character_summary):
		character_summary.text = str(prep.get("character_text", ""))
	if is_instance_valid(progress_summary):
		progress_summary.text = str(prep.get("progress_text", ""))
	if is_instance_valid(resource_summary):
		resource_summary.text = str(prep.get("resource_text", ""))
	if is_instance_valid(growth_summary):
		growth_summary.text = str(prep.get("growth_text", ""))
	if is_instance_valid(start_summary):
		start_summary.text = str(prep.get("start_text", ""))
	if is_instance_valid(prep_recommendations):
		prep_recommendations.text = str(prep.get("recommendation_text", ""))
