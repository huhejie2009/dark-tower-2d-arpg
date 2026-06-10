extends Control

const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")
const SceneRouterScript := preload("res://scripts/app/SceneRouter.gd")
const InventoryEquipmentWindowScript := preload("res://scripts/ui/InventoryEquipmentWindow.gd")
const TownFacilityWindowScript := preload("res://scripts/ui/TownFacilityWindow.gd")
const TownFacilityServiceScript := preload("res://scripts/data/TownFacilityService.gd")
const TowerRunStartServiceScript := preload("res://scripts/data/TowerRunStartService.gd")
const TownPrepSummaryServiceScript := preload("res://scripts/data/TownPrepSummaryService.gd")
const DarkArpgUiThemeScript := preload("res://scripts/ui/DarkArpgUiTheme.gd")

var player_data: Dictionary = {}
var summary: Label
var character_summary: Label
var progress_summary: Label
var resource_summary: Label
var growth_summary: Label
var start_summary: Label
var prep_recommendations: Label
var prep_action_button: Button
var inventory_window: Control
var facility_window: Control
var town_world_root: Node2D
var town_player: CharacterBody2D
var town_interaction_hint: Label
var town_interaction_points: Dictionary = {}
var town_player_speed := 220.0

const TOWN_WORLD_CENTER := Vector2(450, 405)
const TOWN_PANEL_POS := Vector2(880, 92)
const TOWN_PANEL_SIZE := Vector2(360, 420)
const TOWN_BUTTON_X := 920.0
const TOWN_BUTTON_W := 280.0

func _ready() -> void:
	player_data = SaveManagerScript.get_active_player_data()
	_setup_input_actions()
	_build_ui()
	_create_inventory_window()
	_create_facility_window()
	set_process(true)

func _process(delta: float) -> void:
	_update_town_player_movement(delta)
	_update_town_interaction_hint()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_trigger_nearest_town_interaction()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.name = "TownDarkBackground"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = DarkArpgUiThemeScript.COLOR_VOID
	add_child(background)

	_create_town_world_space()

	var title := Label.new()
	title.name = "TownTitle"
	title.text = "Tower Approach"
	title.position = Vector2(226, 18)
	title.size = Vector2(448, 42)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	DarkArpgUiThemeScript.style_title(title, 34)
	add_child(title)

	summary = Label.new()
	summary.name = "TownSummary"
	summary.position = Vector2(190, 72)
	summary.size = Vector2(520, 42)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	DarkArpgUiThemeScript.style_body_label(summary, 18)
	add_child(summary)

	_create_prep_panel()

	var enter := Button.new()
	enter.name = "EnterTowerButton"
	var start_options := TowerRunStartServiceScript.build_start_options(player_data)
	enter.text = str(start_options.get("fresh_label", "Enter Tower: Floor 1"))
	enter.position = Vector2(TOWN_BUTTON_X, 530)
	enter.size = Vector2(TOWN_BUTTON_W, 46)
	DarkArpgUiThemeScript.style_button(enter, true)
	enter.pressed.connect(_enter_fresh_tower_run)
	add_child(enter)

	var best_floor := Button.new()
	best_floor.name = "EnterBestFloorButton"
	best_floor.text = str(start_options.get("best_label", "Challenge Best Floor"))
	best_floor.position = Vector2(TOWN_BUTTON_X, 584)
	best_floor.size = Vector2(TOWN_BUTTON_W, 38)
	DarkArpgUiThemeScript.style_button(best_floor)
	best_floor.pressed.connect(_enter_best_floor_run)
	add_child(best_floor)

	var inventory := Button.new()
	inventory.name = "OpenInventoryButton"
	inventory.text = "Inventory / Equipment"
	inventory.position = Vector2(TOWN_BUTTON_X, 630)
	inventory.size = Vector2(TOWN_BUTTON_W, 38)
	DarkArpgUiThemeScript.style_button(inventory)
	inventory.pressed.connect(_toggle_inventory_window)
	add_child(inventory)

	var menu := Button.new()
	menu.name = "ReturnMainMenuButton"
	menu.text = "Main Menu"
	menu.position = Vector2(TOWN_BUTTON_X, 676)
	menu.size = Vector2(TOWN_BUTTON_W, 34)
	DarkArpgUiThemeScript.style_button(menu)
	menu.pressed.connect(func(): SceneRouterScript.go_to_main_menu(get_tree()))
	add_child(menu)
	_update_summary()

func _setup_input_actions() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("move_forward", [KEY_W, KEY_UP])
	_add_key_action("move_back", [KEY_S, KEY_DOWN])

func _add_key_action(action_name: String, keys: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for keycode in keys:
		var exists := false
		for existing in InputMap.action_get_events(action_name):
			if existing is InputEventKey and existing.keycode == keycode:
				exists = true
				break
		if exists:
			continue
		var event := InputEventKey.new()
		event.keycode = keycode
		InputMap.action_add_event(action_name, event)

func _create_town_world_space() -> void:
	town_world_root = Node2D.new()
	town_world_root.name = "TownWorldRoot"
	town_world_root.position = Vector2(0, 0)
	add_child(town_world_root)

	_add_world_rect("TownGroundPlane", TOWN_WORLD_CENTER, Vector2(780, 470), Color(0.07, 0.085, 0.095, 1.0), Color(0.16, 0.18, 0.19, 1.0))
	_add_world_rect("TownTowerRoad", Vector2(450, 390), Vector2(190, 360), Color(0.12, 0.13, 0.135, 1.0), Color(0.22, 0.23, 0.23, 1.0))
	_add_world_rect("TownTowerSilhouette", Vector2(450, 218), Vector2(170, 220), Color(0.035, 0.045, 0.055, 1.0), Color(0.16, 0.20, 0.25, 1.0))
	_add_world_rect("TownTowerDarkCore", Vector2(450, 218), Vector2(22, 220), Color(0.015, 0.08, 0.12, 1.0), Color(0.18, 0.38, 0.46, 1.0))
	_add_world_rect("TownMerchantStall", Vector2(160, 414), Vector2(130, 82), Color(0.12, 0.09, 0.075, 1.0), Color(0.35, 0.25, 0.16, 1.0))
	_add_world_rect("TownBlacksmithForge", Vector2(730, 410), Vector2(150, 90), Color(0.10, 0.09, 0.085, 1.0), Color(0.32, 0.15, 0.10, 1.0))
	_add_world_rect("TownStashCrate", Vector2(220, 610), Vector2(110, 78), Color(0.09, 0.08, 0.07, 1.0), Color(0.28, 0.22, 0.16, 1.0))
	_add_world_rect("TownTrainingCircle", Vector2(720, 610), Vector2(128, 78), Color(0.07, 0.08, 0.08, 1.0), Color(0.18, 0.26, 0.28, 1.0))

	_add_town_interaction_point("tower_gate", "TownTowerGateInteraction", "Tower Gate", Vector2(450, 340), "enter_tower")
	_add_town_interaction_point("merchant", "TownMerchantInteraction", "Merchant", Vector2(160, 486), "open_facility")
	_add_town_interaction_point("blacksmith", "TownBlacksmithInteraction", "Blacksmith", Vector2(730, 486), "open_facility")
	_add_town_interaction_point("stash", "TownStashInteraction", "Stash", Vector2(220, 675), "open_facility")
	_add_town_interaction_point("training", "TownTrainingInteraction", "Training", Vector2(720, 675), "open_facility")

	town_player = CharacterBody2D.new()
	town_player.name = "TownPlayer"
	town_player.global_position = Vector2(450, 610)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	shape.shape = circle
	town_player.add_child(shape)
	var body := Polygon2D.new()
	body.name = "TownPlayerBody"
	body.polygon = PackedVector2Array([Vector2(0, -22), Vector2(14, -8), Vector2(10, 18), Vector2(-10, 18), Vector2(-14, -8)])
	body.color = Color(0.18, 0.22, 0.24, 1.0)
	town_player.add_child(body)
	var cloak := Polygon2D.new()
	cloak.name = "TownPlayerCloak"
	cloak.polygon = PackedVector2Array([Vector2(-9, -4), Vector2(9, -4), Vector2(16, 24), Vector2(-16, 24)])
	cloak.color = Color(0.035, 0.05, 0.065, 1.0)
	town_player.add_child(cloak)
	town_world_root.add_child(town_player)

	town_interaction_hint = Label.new()
	town_interaction_hint.name = "TownInteractionHint"
	town_interaction_hint.position = Vector2(250, 682)
	town_interaction_hint.size = Vector2(400, 30)
	town_interaction_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	DarkArpgUiThemeScript.style_body_label(town_interaction_hint, 15, true)
	add_child(town_interaction_hint)

func _add_world_rect(node_name: String, center: Vector2, size: Vector2, fill: Color, outline: Color) -> void:
	var rect := Polygon2D.new()
	rect.name = node_name
	var half := size * 0.5
	rect.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	rect.position = center
	rect.color = fill
	town_world_root.add_child(rect)
	var line := Line2D.new()
	line.name = "%sOutline" % node_name
	line.points = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
		Vector2(-half.x, -half.y),
	])
	line.position = center
	line.width = 2.0
	line.default_color = outline
	town_world_root.add_child(line)

func _add_town_interaction_point(id: String, node_name: String, display_name: String, point: Vector2, action_id: String) -> void:
	var area := Area2D.new()
	area.name = node_name
	area.global_position = point
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 42.0
	shape.shape = circle
	area.add_child(shape)
	var marker := Polygon2D.new()
	marker.name = "%sMarker" % node_name
	marker.polygon = PackedVector2Array([Vector2(0, -10), Vector2(10, 0), Vector2(0, 10), Vector2(-10, 0)])
	marker.color = DarkArpgUiThemeScript.COLOR_GOLD
	area.add_child(marker)
	var label := Label.new()
	label.name = "%sLabel" % node_name
	label.text = display_name
	label.position = Vector2(-70, -44)
	label.size = Vector2(140, 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	DarkArpgUiThemeScript.style_body_label(label, 13, true)
	area.add_child(label)
	town_world_root.add_child(area)
	town_interaction_points[id] = {
		"id": id,
		"display_name": display_name,
		"position": point,
		"action_id": action_id,
	}

func _create_prep_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "TownPrepPanel"
	panel.position = TOWN_PANEL_POS
	panel.size = TOWN_PANEL_SIZE
	DarkArpgUiThemeScript.style_panel(panel, true)
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var panel_title := Label.new()
	panel_title.text = "Preparation"
	DarkArpgUiThemeScript.style_title(panel_title, 20)
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
	start_summary.custom_minimum_size = Vector2(320, 54)
	box.add_child(start_summary)
	prep_recommendations = _make_prep_label("TownPrepRecommendations")
	prep_recommendations.custom_minimum_size = Vector2(320, 64)
	box.add_child(prep_recommendations)
	prep_action_button = Button.new()
	prep_action_button.name = "TownPrepActionButton"
	prep_action_button.text = "Open Prep"
	prep_action_button.custom_minimum_size = Vector2(220, 34)
	DarkArpgUiThemeScript.style_button(prep_action_button, true)
	prep_action_button.pressed.connect(_on_prep_action_pressed)
	box.add_child(prep_action_button)

func _make_prep_label(label_name: String) -> Label:
	var label := Label.new()
	label.name = label_name
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(320, 24)
	DarkArpgUiThemeScript.style_body_label(label, 15)
	return label

func get_ui_style_id_for_test() -> String:
	return DarkArpgUiThemeScript.get_style_id()

func _create_inventory_window() -> void:
	inventory_window = InventoryEquipmentWindowScript.new()
	add_child(inventory_window)
	inventory_window.set_player_data(player_data)
	inventory_window.player_data_changed.connect(_on_player_data_changed)
	inventory_window.close_requested.connect(func(): inventory_window.visible = false)

func _create_facility_window() -> void:
	facility_window = TownFacilityWindowScript.new()
	add_child(facility_window)
	facility_window.close_requested.connect(func(): pass)
	facility_window.action_requested.connect(_on_town_facility_action_requested)

func _toggle_inventory_window() -> void:
	inventory_window.visible = not inventory_window.visible
	if inventory_window.visible:
		inventory_window.set_player_data(player_data)

func _on_prep_action_pressed() -> void:
	var prep := TownPrepSummaryServiceScript.build_summary(player_data)
	var recommendations := Dictionary(prep.get("recommendations", {}))
	_open_prep_action(str(recommendations.get("primary_action_id", "")))

func _open_prep_action(action_id: String) -> void:
	if not is_instance_valid(inventory_window):
		return
	inventory_window.visible = true
	inventory_window.set_player_data(player_data)
	match action_id:
		"open_equipment":
			if inventory_window.has_method("set_filter_mode"):
				inventory_window.call("set_filter_mode", "equipment")
		"open_inventory":
			if inventory_window.has_method("set_filter_mode"):
				inventory_window.call("set_filter_mode", "all")
		"open_skills":
			if inventory_window.has_method("set_filter_mode"):
				inventory_window.call("set_filter_mode", "all")
			if inventory_window.has_method("select_skill_node"):
				inventory_window.call("select_skill_node", "basic_attack_training")
		_:
			pass

func _update_town_player_movement(delta: float) -> void:
	if not is_instance_valid(town_player):
		return
	if is_instance_valid(inventory_window) and inventory_window.visible:
		return
	if is_instance_valid(facility_window) and facility_window.visible:
		return
	var direction := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if direction.length_squared() <= 0.001:
		town_player.velocity = Vector2.ZERO
		return
	_move_town_player(direction, delta)

func _move_town_player(direction: Vector2, delta: float) -> void:
	if not is_instance_valid(town_player) or direction.length_squared() <= 0.001:
		return
	var next_position := town_player.global_position + direction.normalized() * town_player_speed * delta
	town_player.global_position = _clamp_town_player_position(next_position)

func _clamp_town_player_position(position: Vector2) -> Vector2:
	return Vector2(clampf(position.x, 70.0, 830.0), clampf(position.y, 300.0, 685.0))

func _update_town_interaction_hint() -> void:
	if not is_instance_valid(town_interaction_hint):
		return
	var nearest := _get_nearest_town_interaction()
	if nearest.is_empty():
		town_interaction_hint.text = "WASD Move"
		return
	town_interaction_hint.text = "E  %s" % str(nearest.get("display_name", "Interact"))

func _get_nearest_town_interaction() -> Dictionary:
	if not is_instance_valid(town_player):
		return {}
	var best: Dictionary = {}
	var best_distance := 999999.0
	for id in town_interaction_points.keys():
		var data: Dictionary = Dictionary(town_interaction_points[id])
		var distance := town_player.global_position.distance_to(Vector2(data.get("position", Vector2.ZERO)))
		if distance < 72.0 and distance < best_distance:
			best = data
			best_distance = distance
	return best

func _trigger_nearest_town_interaction() -> void:
	var nearest := _get_nearest_town_interaction()
	if nearest.is_empty():
		return
	_trigger_town_interaction(str(nearest.get("id", "")))

func _trigger_town_interaction(id: String) -> void:
	var data: Dictionary = Dictionary(town_interaction_points.get(id, {}))
	if data.is_empty():
		return
	match str(data.get("action_id", "")):
		"enter_tower":
			_enter_fresh_tower_run()
		"open_facility":
			_open_town_facility(id)
		_:
			pass

func _open_town_facility(id: String) -> void:
	if not is_instance_valid(facility_window):
		return
	if TownFacilityServiceScript.get_facility_config(id).is_empty():
		return
	if is_instance_valid(inventory_window):
		inventory_window.visible = false
	facility_window.call("open_facility", id)

func _on_town_facility_action_requested(facility_id: String, action_id: String) -> void:
	var action := TownFacilityServiceScript.get_action_config(facility_id, action_id)
	if action.is_empty():
		return
	match str(action.get("kind", "")):
		"inventory_filter":
			_open_inventory_filter(str(action.get("filter_mode", "all")))
		"skill_panel":
			_open_prep_action("open_skills")
		"inventory_action":
			_open_inventory_filter("all")
			match str(action.get("inventory_action", "")):
				"sell_junk":
					if inventory_window.has_method("sell_junk_items"):
						inventory_window.call("sell_junk_items")
				"salvage_junk":
					if inventory_window.has_method("salvage_junk_items"):
						inventory_window.call("salvage_junk_items")
				_:
					pass
		_:
			pass

func _open_inventory_filter(filter_mode: String) -> void:
	if not is_instance_valid(inventory_window):
		return
	inventory_window.visible = true
	inventory_window.set_player_data(player_data)
	if inventory_window.has_method("set_filter_mode"):
		inventory_window.call("set_filter_mode", filter_mode)

func get_town_interaction_points_for_test() -> Dictionary:
	return town_interaction_points.duplicate(true)

func get_town_player_position_for_test() -> Vector2:
	if not is_instance_valid(town_player):
		return Vector2.ZERO
	return town_player.global_position

func move_town_player_for_test(direction: Vector2, seconds: float) -> void:
	_move_town_player(direction, maxf(0.0, seconds))

func trigger_town_interaction_for_test(id: String) -> void:
	_trigger_town_interaction(id)

func get_open_town_facility_id_for_test() -> String:
	if not is_instance_valid(facility_window) or not facility_window.has_method("get_open_facility_id"):
		return ""
	return str(facility_window.call("get_open_facility_id"))

func trigger_town_facility_action_for_test(facility_id: String, action_id: String) -> void:
	_open_town_facility(facility_id)
	_on_town_facility_action_requested(facility_id, action_id)

func trigger_prep_action_for_test() -> void:
	_on_prep_action_pressed()

func get_prep_primary_action_for_test() -> Dictionary:
	var prep := TownPrepSummaryServiceScript.build_summary(player_data)
	return Dictionary(prep.get("recommendations", {}))

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
	if is_instance_valid(prep_action_button):
		var recommendations := Dictionary(prep.get("recommendations", {}))
		var has_action := bool(recommendations.get("has_action", false))
		prep_action_button.disabled = not has_action
		prep_action_button.text = str(recommendations.get("primary_button_text", "Ready"))
