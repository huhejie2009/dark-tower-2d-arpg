extends Control
class_name InventoryEquipmentWindow

signal player_data_changed(player_data: Dictionary)
signal close_requested

const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const InventoryQueryServiceScript := preload("res://scripts/data/InventoryQueryService.gd")
const InventoryItemActionServiceScript := preload("res://scripts/data/InventoryItemActionService.gd")
const EquipmentDataServiceScript := preload("res://scripts/data/EquipmentDataService.gd")
const EquipmentActionHintServiceScript := preload("res://scripts/data/EquipmentActionHintService.gd")
const EquipmentCompareSummaryServiceScript := preload("res://scripts/data/EquipmentCompareSummaryService.gd")
const EquipmentRecommendationServiceScript := preload("res://scripts/data/EquipmentRecommendationService.gd")
const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const SkillNodeGrowthServiceScript := preload("res://scripts/data/SkillNodeGrowthService.gd")
const SkillUpgradePreviewServiceScript := preload("res://scripts/data/SkillUpgradePreviewService.gd")
const GemSocketServiceScript := preload("res://scripts/data/GemSocketService.gd")
const ClassRulesScript := preload("res://scripts/rules/ClassRules.gd")
const GameConstantsScript := preload("res://scripts/app/GameConstants.gd")
const DarkArpgUiThemeScript := preload("res://scripts/ui/DarkArpgUiTheme.gd")

const DEFAULT_WINDOW_SIZE := Vector2(980, 600)
const VIEWPORT_MARGIN := 32.0
const WIDE_LAYOUT_MIN_WIDTH := 940.0
const WIDE_GRID_COLUMNS := 9
const COMPACT_GRID_COLUMNS := 6
const DETAIL_WIDE_MIN_WIDTH := 260.0
const DETAIL_SCROLL_MIN_HEIGHT := 132.0

var player_data: Dictionary = {}
var inventory_grid: GridContainer
var equipment_box: VBoxContainer
var inventory_title_label: Label
var paper_doll_class_label: Label
var paper_doll_score_label: Label
var paper_doll_anchor: Control
var stats_label: Label
var skill_point_summary: Label
var skill_node_list: VBoxContainer
var upgrade_basic_attack_button: Button
var upgrade_selected_skill_button: Button
var detail_label: Label
var equip_selected_button: Button
var lock_selected_button: Button
var favorite_selected_button: Button
var junk_selected_button: Button
var clear_selected_button: Button
var sell_junk_button: Button
var salvage_junk_button: Button
var junk_action_confirm_dialog: ConfirmationDialog
var pending_junk_action_mode: String = ""
var pending_junk_action_preview: Dictionary = {}
var filter_mode: String = "all"
var sort_mode: String = "type"
var selected_item_id: String = ""
var selected_skill_node_id: String = PlayerDataServiceScript.BASIC_ATTACK_TRAINING_NODE
var filter_buttons: Dictionary = {}

func _ready() -> void:
	_build_ui()
	_sync_layout_to_viewport()
	get_viewport().size_changed.connect(_sync_layout_to_viewport)
	refresh()

func set_player_data(data: Dictionary) -> void:
	player_data = data.duplicate(true)
	refresh()

func refresh() -> void:
	if not is_instance_valid(inventory_grid):
		return
	for child in inventory_grid.get_children():
		child.queue_free()
	for child in equipment_box.get_children():
		child.queue_free()
	_build_equipment_slots()
	_build_inventory_grid()
	_update_stats()
	_update_skill_summary()
	_sync_selected_detail()

func _build_ui() -> void:
	name = "InventoryEquipmentWindow"
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	_sync_layout_to_viewport()
	visible = false

	var panel := PanelContainer.new()
	panel.name = "InventoryEquipmentPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	DarkArpgUiThemeScript.style_panel(panel, true)
	add_child(panel)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 8)
	panel.add_child(root_box)

	junk_action_confirm_dialog = ConfirmationDialog.new()
	junk_action_confirm_dialog.name = "JunkActionConfirmDialog"
	junk_action_confirm_dialog.title = "处理废品"
	junk_action_confirm_dialog.dialog_text = ""
	junk_action_confirm_dialog.confirmed.connect(_confirm_pending_junk_action)
	add_child(junk_action_confirm_dialog)

	var header := HBoxContainer.new()
	root_box.add_child(header)

	var title := Label.new()
	title.text = "背包与装备"
	DarkArpgUiThemeScript.style_title(title, 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_button := Button.new()
	close_button.name = "CloseInventoryButton"
	close_button.text = "关"
	close_button.custom_minimum_size = Vector2(36, 32)
	DarkArpgUiThemeScript.style_button(close_button)
	close_button.pressed.connect(func(): close_requested.emit())
	header.add_child(close_button)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root_box.add_child(body)

	equipment_box = VBoxContainer.new()
	equipment_box.name = "EquipmentSlots"
	equipment_box.custom_minimum_size = Vector2(190, 0)
	body.add_child(equipment_box)

	var inventory_panel := VBoxContainer.new()
	inventory_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(inventory_panel)

	inventory_title_label = Label.new()
	inventory_title_label.name = "InventoryCapacityTitle"
	inventory_title_label.text = "背包"
	DarkArpgUiThemeScript.style_title(inventory_title_label, 17)
	inventory_panel.add_child(inventory_title_label)

	var tools := HBoxContainer.new()
	tools.name = "InventoryTools"
	tools.add_theme_constant_override("separation", 4)
	inventory_panel.add_child(tools)

	var sort_button := Button.new()
	sort_button.name = "SortInventoryButton"
	sort_button.text = "排序：类型"
	sort_button.custom_minimum_size = Vector2(62, 30)
	DarkArpgUiThemeScript.style_button(sort_button)
	sort_button.pressed.connect(_cycle_sort_mode)
	tools.add_child(sort_button)

	_add_filter_button(tools, "all", "FilterAllButton", "全部", 52, true)
	_add_filter_button(tools, "equipment", "FilterEquipmentButton", "装备", 64)
	_add_filter_button(tools, "material", "FilterMaterialButton", "材料", 52)
	_add_filter_button(tools, "upgrade", "FilterUpgradeButton", "提升", 52)
	_add_filter_button(tools, "locked", "FilterLockedButton", "锁定", 58)
	_add_filter_button(tools, "favorite", "FilterFavoriteButton", "收藏", 52)
	_add_filter_button(tools, "junk", "FilterJunkButton", "废品", 58)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_panel.add_child(scroll)

	inventory_grid = GridContainer.new()
	inventory_grid.name = "InventoryGrid"
	inventory_grid.columns = 8
	scroll.add_child(inventory_grid)

	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(DETAIL_WIDE_MIN_WIDTH, 0)
	side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(side)

	stats_label = Label.new()
	stats_label.name = "StatsSummary"
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_label.custom_minimum_size = Vector2(200, 150)
	DarkArpgUiThemeScript.style_body_label(stats_label)
	side.add_child(stats_label)

	var skill_title := Label.new()
	skill_title.text = "天赋"
	DarkArpgUiThemeScript.style_title(skill_title, 16)
	side.add_child(skill_title)

	skill_point_summary = Label.new()
	skill_point_summary.name = "SkillPointSummary"
	skill_point_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skill_point_summary.custom_minimum_size = Vector2(200, 56)
	DarkArpgUiThemeScript.style_body_label(skill_point_summary)
	side.add_child(skill_point_summary)

	skill_node_list = VBoxContainer.new()
	skill_node_list.name = "SkillNodeList"
	skill_node_list.add_theme_constant_override("separation", 3)
	side.add_child(skill_node_list)

	upgrade_selected_skill_button = Button.new()
	upgrade_selected_skill_button.name = "UpgradeSelectedSkillButton"
	upgrade_selected_skill_button.text = "升级所选"
	upgrade_selected_skill_button.custom_minimum_size = Vector2(200, 32)
	DarkArpgUiThemeScript.style_button(upgrade_selected_skill_button, true)
	upgrade_selected_skill_button.pressed.connect(upgrade_selected_skill_node)
	side.add_child(upgrade_selected_skill_button)

	upgrade_basic_attack_button = Button.new()
	upgrade_basic_attack_button.name = "UpgradeBasicAttackButton"
	upgrade_basic_attack_button.text = "升级基础攻击"
	upgrade_basic_attack_button.custom_minimum_size = Vector2(200, 36)
	DarkArpgUiThemeScript.style_button(upgrade_basic_attack_button, true)
	upgrade_basic_attack_button.pressed.connect(_on_upgrade_basic_attack_pressed)
	side.add_child(upgrade_basic_attack_button)

	var detail_scroll := ScrollContainer.new()
	detail_scroll.name = "ItemDetailScroll"
	detail_scroll.custom_minimum_size = Vector2(DETAIL_WIDE_MIN_WIDTH, DETAIL_SCROLL_MIN_HEIGHT)
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(detail_scroll)

	detail_label = Label.new()
	detail_label.name = "ItemDetail"
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DarkArpgUiThemeScript.style_body_label(detail_label)
	detail_scroll.add_child(detail_label)

	var action_row := HBoxContainer.new()
	action_row.name = "SelectedItemActions"
	action_row.add_theme_constant_override("separation", 4)
	side.add_child(action_row)

	equip_selected_button = Button.new()
	equip_selected_button.name = "EquipSelectedButton"
	equip_selected_button.text = "装备"
	equip_selected_button.custom_minimum_size = Vector2(72, 32)
	DarkArpgUiThemeScript.style_button(equip_selected_button, true)
	equip_selected_button.pressed.connect(use_selected_item)
	action_row.add_child(equip_selected_button)

	lock_selected_button = Button.new()
	lock_selected_button.name = "LockSelectedButton"
	lock_selected_button.text = "锁定"
	lock_selected_button.custom_minimum_size = Vector2(72, 32)
	DarkArpgUiThemeScript.style_button(lock_selected_button)
	lock_selected_button.pressed.connect(toggle_selected_lock)
	action_row.add_child(lock_selected_button)

	favorite_selected_button = Button.new()
	favorite_selected_button.name = "FavoriteSelectedButton"
	favorite_selected_button.text = "收藏"
	favorite_selected_button.custom_minimum_size = Vector2(62, 32)
	DarkArpgUiThemeScript.style_button(favorite_selected_button)
	favorite_selected_button.pressed.connect(toggle_selected_favorite)
	action_row.add_child(favorite_selected_button)

	junk_selected_button = Button.new()
	junk_selected_button.name = "JunkSelectedButton"
	junk_selected_button.text = "废品"
	junk_selected_button.custom_minimum_size = Vector2(62, 32)
	DarkArpgUiThemeScript.style_button(junk_selected_button)
	junk_selected_button.pressed.connect(toggle_selected_junk)
	action_row.add_child(junk_selected_button)

	clear_selected_button = Button.new()
	clear_selected_button.name = "ClearSelectedButton"
	clear_selected_button.text = "清除"
	clear_selected_button.custom_minimum_size = Vector2(72, 32)
	DarkArpgUiThemeScript.style_button(clear_selected_button)
	clear_selected_button.pressed.connect(clear_selection)
	action_row.add_child(clear_selected_button)

	var batch_row := HBoxContainer.new()
	batch_row.name = "BatchJunkActions"
	batch_row.add_theme_constant_override("separation", 4)
	side.add_child(batch_row)

	sell_junk_button = Button.new()
	sell_junk_button.name = "SellJunkButton"
	sell_junk_button.text = "出售废品"
	sell_junk_button.custom_minimum_size = Vector2(96, 32)
	DarkArpgUiThemeScript.style_button(sell_junk_button)
	sell_junk_button.pressed.connect(sell_junk_items)
	batch_row.add_child(sell_junk_button)

	salvage_junk_button = Button.new()
	salvage_junk_button.name = "SalvageJunkButton"
	salvage_junk_button.text = "分解"
	salvage_junk_button.custom_minimum_size = Vector2(96, 32)
	DarkArpgUiThemeScript.style_button(salvage_junk_button)
	salvage_junk_button.pressed.connect(salvage_junk_items)
	batch_row.add_child(salvage_junk_button)
	_sync_filter_button_states()

func _add_filter_button(parent: Container, mode: String, button_name: String, text: String, width: int, selected: bool = false) -> void:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.custom_minimum_size = Vector2(width, 30)
	button.toggle_mode = true
	DarkArpgUiThemeScript.style_toggle_button(button, selected)
	button.pressed.connect(set_filter_mode.bind(mode))
	filter_buttons[mode] = button
	parent.add_child(button)

func _sync_layout_to_viewport() -> void:
	var viewport_size := _get_layout_viewport_size()
	var window_size := _get_responsive_window_size(viewport_size)
	offset_left = -window_size.x * 0.5
	offset_top = -window_size.y * 0.5
	offset_right = window_size.x * 0.5
	offset_bottom = window_size.y * 0.5
	if is_instance_valid(inventory_grid):
		inventory_grid.columns = WIDE_GRID_COLUMNS if window_size.x >= WIDE_LAYOUT_MIN_WIDTH else COMPACT_GRID_COLUMNS

func _get_layout_viewport_size() -> Vector2:
	var parent := get_parent()
	if parent is Window:
		var window_size := Vector2((parent as Window).size)
		if window_size.x > 0.0 and window_size.y > 0.0:
			return window_size
	return Vector2(get_viewport().get_visible_rect().size)

func _get_responsive_window_size(viewport_size: Vector2) -> Vector2:
	return Vector2(
		minf(DEFAULT_WINDOW_SIZE.x, maxf(360.0, viewport_size.x - VIEWPORT_MARGIN)),
		minf(DEFAULT_WINDOW_SIZE.y, maxf(360.0, viewport_size.y - VIEWPORT_MARGIN))
	)

func get_responsive_window_rect_for_test(viewport_size: Vector2) -> Rect2:
	var window_size := _get_responsive_window_size(viewport_size)
	return Rect2((viewport_size - window_size) * 0.5, window_size)

func get_visual_qa_metrics_for_test(viewport_size: Vector2) -> Dictionary:
	var window_size := _get_responsive_window_size(viewport_size)
	return {
		"window_size": window_size,
		"grid_columns": WIDE_GRID_COLUMNS if window_size.x >= WIDE_LAYOUT_MIN_WIDTH else COMPACT_GRID_COLUMNS,
		"detail_min_width": DETAIL_WIDE_MIN_WIDTH,
		"detail_scroll_min_height": DETAIL_SCROLL_MIN_HEIGHT,
		"default_window_size": DEFAULT_WINDOW_SIZE,
	}

func _build_equipment_slots() -> void:
	var title := Label.new()
	title.text = "装备"
	DarkArpgUiThemeScript.style_title(title, 17)
	equipment_box.add_child(title)
	var paper_panel := PanelContainer.new()
	paper_panel.custom_minimum_size = Vector2(190, 214)
	DarkArpgUiThemeScript.style_panel(paper_panel)
	equipment_box.add_child(paper_panel)
	paper_panel.name = "EquipmentPaperDollPanel"

	var paper_root := VBoxContainer.new()
	paper_root.add_theme_constant_override("separation", 6)
	paper_panel.add_child(paper_root)
	var paper_marker := Control.new()
	paper_marker.name = "EquipmentPaperDollPanel"
	paper_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper_marker.custom_minimum_size = Vector2.ZERO
	paper_root.add_child(paper_marker)

	paper_doll_class_label = Label.new()
	paper_doll_class_label.name = "PaperDollClassLabel"
	paper_doll_class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	paper_doll_class_label.text = ClassRulesScript.get_class_name(str(player_data.get("base_class", "warrior")))
	DarkArpgUiThemeScript.style_body_label(paper_doll_class_label, 15)
	paper_root.add_child(paper_doll_class_label)

	paper_doll_anchor = Control.new()
	paper_doll_anchor.name = "PaperDollAnchor"
	paper_doll_anchor.custom_minimum_size = Vector2(170, 118)
	paper_root.add_child(paper_doll_anchor)
	_build_paper_doll_placeholder(paper_doll_anchor)

	paper_doll_score_label = Label.new()
	paper_doll_score_label.name = "PaperDollScoreLabel"
	paper_doll_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	paper_doll_score_label.text = "装备评分 %d" % _get_total_equipment_score()
	DarkArpgUiThemeScript.style_body_label(paper_doll_score_label, 14, true)
	paper_root.add_child(paper_doll_score_label)

	var equipped: Dictionary = Dictionary(player_data.get("equipped_items", {}))
	var inventory: Dictionary = Dictionary(player_data.get("inventory", {}))
	for slot in GameConstantsScript.EQUIPMENT_SLOTS:
		var button := Button.new()
		var button_name := "EquipmentSlot%s" % _slot_node_suffix(slot)
		button.custom_minimum_size = Vector2(174, 42)
		var summary := _build_equipment_slot_summary(slot, equipped, inventory)
		button.text = str(summary.get("button_text", "%s：空" % _slot_label(slot)))
		button.tooltip_text = str(summary.get("tooltip", ""))
		DarkArpgUiThemeScript.style_button(button)
		var button_marker := Control.new()
		button_marker.name = button_name
		button_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(button_marker)
		button.pressed.connect(_on_equipment_slot_pressed.bind(slot))
		equipment_box.add_child(button)
		button.name = button_name

func _build_paper_doll_placeholder(parent: Control) -> void:
	var silhouette := PanelContainer.new()
	silhouette.name = "PaperDollSilhouette"
	silhouette.position = Vector2(52, 8)
	silhouette.size = Vector2(66, 102)
	DarkArpgUiThemeScript.style_panel(silhouette, true)
	parent.add_child(silhouette)

	var label := Label.new()
	label.name = "PaperDollPlaceholderLabel"
	label.text = "美术\n定位"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", DarkArpgUiThemeScript.COLOR_MUTED)
	silhouette.add_child(label)

	var left_tag := _make_paper_doll_tag("武器", Vector2(4, 34))
	parent.add_child(left_tag)
	var right_tag := _make_paper_doll_tag("护甲", Vector2(118, 34))
	parent.add_child(right_tag)
	var bottom_tag := _make_paper_doll_tag("戒指", Vector2(61, 88))
	parent.add_child(bottom_tag)

func _make_paper_doll_tag(text: String, position: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = Vector2(56, 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", DarkArpgUiThemeScript.COLOR_MUTED)
	return label

func _slot_node_suffix(slot: String) -> String:
	if slot == "":
		return "Unknown"
	return slot.substr(0, 1).to_upper() + slot.substr(1)

func _build_inventory_grid() -> void:
	var inventory: Dictionary = InventoryDataServiceScript.normalize_inventory(player_data.get("inventory", {}))
	_update_inventory_capacity_title(inventory)
	var item_ids := get_visible_item_ids()
	for item_id in item_ids:
		var entry: Dictionary = Dictionary(inventory[item_id])
		var button := Button.new()
		button.name = "InventoryItem%s" % str(item_id).capitalize()
		button.custom_minimum_size = Vector2(58, 58)
		var visual_meta := _build_item_visual_metadata(str(item_id), entry)
		button.text = str(visual_meta.get("label", _item_short_text(entry)))
		if str(item_id) == selected_item_id:
			button.text = "*%s" % button.text
		button.tooltip_text = _describe_item(entry)
		_apply_item_button_style(button, visual_meta)
		button.pressed.connect(_on_inventory_item_pressed.bind(str(item_id)))
		inventory_grid.add_child(button)
	for _i in range(maxi(0, 32 - item_ids.size())):
		var empty := PanelContainer.new()
		empty.custom_minimum_size = Vector2(58, 58)
		DarkArpgUiThemeScript.style_panel(empty)
		inventory_grid.add_child(empty)

func _item_short_text(entry: Dictionary) -> String:
	var item_type := str(entry.get("type", "item"))
	if item_type == "equipment":
		var equipment: Dictionary = Dictionary(entry.get("equipment", {}))
		return _slot_short_label(str(equipment.get("slot", "")))
	return _stack_short_label(entry)

func _stack_short_label(entry: Dictionary) -> String:
	var item_type := str(entry.get("type", "item"))
	var item_name := str(entry.get("name", entry.get("id", "")))
	var amount := int(entry.get("amount", 1))
	var hint := "物"
	if item_type == "currency":
		hint = "金"
	elif item_type == "material":
		hint = "晶" if item_name.contains("晶") or str(entry.get("id", "")).contains("crystal") else "材"
	return "%s\n%d" % [hint, amount]

func _describe_item(entry: Dictionary) -> String:
	var lines: Array[String] = [str(entry.get("name", entry.get("id", "物品")))]
	lines.append("类型：%s" % _item_type_label(str(entry.get("type", "item"))))
	if bool(entry.get("locked", false)):
		lines.append("已锁定")
	if str(entry.get("type", "")) == "equipment":
		var equipment: Dictionary = Dictionary(entry.get("equipment", {}))
		lines.append("槽位：%s" % _slot_label(str(equipment.get("slot", ""))))
		lines.append("等级：%d" % int(equipment.get("item_level", 1)))
		lines.append("稀有度：%s" % _rarity_label(str(equipment.get("rarity", "common"))))
		lines.append("评分：%d" % EquipmentDataServiceScript.get_equipment_score(equipment))
		lines.append("职业池：%s" % ClassRulesScript.get_class_name(str(equipment.get("equipment_pool", ""))))
		lines.append_array(_build_socket_detail_lines(equipment))
		var action_hint := _build_item_action_hint(str(entry.get("id", equipment.get("instance_id", ""))))
		if not action_hint.is_empty():
			lines.append("操作：")
			lines.append(str(action_hint.get("primary_text", "")))
			lines.append(str(action_hint.get("button_text", "")))
			var action_detail := str(action_hint.get("detail_text", ""))
			if action_detail != "":
				lines.append(action_detail)
		var recommendation := _build_item_recommendation(str(entry.get("id", equipment.get("instance_id", ""))), entry)
		if not recommendation.is_empty():
			var source_label := str(recommendation.get("source_label", ""))
			var quality_tag := str(recommendation.get("quality_tag", ""))
			var recommendation_text := str(recommendation.get("recommendation_text", ""))
			var score_delta := int(recommendation.get("score_delta", 0))
			var score_sign := "+" if score_delta > 0 else ""
			if source_label != "":
				lines.append("来源：%s" % source_label)
			if quality_tag != "":
				lines.append("品质：%s" % quality_tag)
			if recommendation_text != "":
				lines.append("推荐：%s" % recommendation_text)
			lines.append("评分差：%s%d" % [score_sign, score_delta])
		if EquipmentDataServiceScript.is_equipped_item(player_data, str(entry.get("id", ""))):
			lines.append("当前已装备")
		var affixes: Dictionary = Dictionary(equipment.get("affixes", {}))
		for stat_id in affixes.keys():
			lines.append("+%d %s" % [int(affixes[stat_id]), _stat_label(str(stat_id))])
		var compare_summary := _build_item_compare_summary(str(entry.get("id", equipment.get("instance_id", ""))), equipment)
		if not compare_summary.is_empty():
			lines.append("装备对比：")
			lines.append(str(compare_summary.get("headline", "")))
			lines.append(str(compare_summary.get("compact_text", "")))
			for reason in Array(compare_summary.get("reason_lines", [])):
				lines.append("- %s" % str(reason))
		lines.append_array(_build_compare_lines(equipment))
	else:
		if _is_gem_entry(entry):
			var gem_id := _get_entry_gem_id(entry)
			var gem_def := GemSocketServiceScript.get_gem_definition(gem_id)
			var stats: Dictionary = Dictionary(gem_def.get("stats", {}))
			for stat_id in stats.keys():
				lines.append("+%d %s" % [int(stats[stat_id]), _stat_label(str(stat_id))])
		lines.append("数量：%d" % int(entry.get("amount", 1)))
	return "\n".join(lines)

func _build_socket_detail_lines(equipment: Dictionary) -> Array[String]:
	var limit := GemSocketServiceScript.get_socket_limit(str(equipment.get("slot", "")))
	if limit <= 0:
		return []
	var socketed := GemSocketServiceScript.normalize_socketed_gems(equipment)
	var lines: Array[String] = ["宝石孔：%d/%d" % [socketed.size(), limit]]
	if not socketed.is_empty():
		var names: Array[String] = []
		for gem_id in socketed:
			names.append(GemSocketServiceScript.get_gem_name(str(gem_id)))
		lines.append("已镶嵌：%s" % "、".join(names))
	var preview := _build_socket_preview_for_equipment(equipment)
	if bool(preview.get("can_socket", false)):
		lines.append("可镶嵌：%s" % str(preview.get("gem_name", "")))
	return lines

func _build_compare_lines(candidate_equipment: Dictionary) -> Array[String]:
	var summary := _build_item_compare_summary(str(candidate_equipment.get("instance_id", "")), candidate_equipment)
	if summary.is_empty():
		return []
	if bool(summary.get("empty_slot", false)):
		return ["对比：空槽位"]
	var lines: Array[String] = ["对比："]
	for row in Array(summary.get("stat_deltas", [])):
		lines.append(str(Dictionary(row).get("compact_text", "")))
		var reason := str(Dictionary(row).get("reason_text", ""))
		if reason != "":
			lines.append("  %s" % reason)
	if lines.size() == 1:
		lines.append("属性无变化")
	return lines

func describe_item_for_test(item_id: String) -> String:
	var inventory: Dictionary = Dictionary(player_data.get("inventory", {}))
	if not inventory.has(item_id):
		return ""
	return _describe_item(Dictionary(inventory[item_id]))

func get_selected_item_id() -> String:
	return selected_item_id

func get_item_score_for_test(item_id: String) -> int:
	var inventory: Dictionary = Dictionary(player_data.get("inventory", {}))
	if not inventory.has(item_id):
		return 0
	var entry: Dictionary = Dictionary(inventory[item_id])
	if str(entry.get("type", "")) != "equipment":
		return 0
	return EquipmentDataServiceScript.get_item_score(player_data, item_id)

func get_item_visual_metadata_for_test(item_id: String) -> Dictionary:
	var inventory: Dictionary = InventoryDataServiceScript.normalize_inventory(player_data.get("inventory", {}))
	if not inventory.has(item_id):
		return {}
	return _build_item_visual_metadata(item_id, Dictionary(inventory[item_id]))

func get_item_recommendation_for_test(item_id: String) -> Dictionary:
	var inventory: Dictionary = InventoryDataServiceScript.normalize_inventory(player_data.get("inventory", {}))
	if not inventory.has(item_id):
		return {}
	return _build_item_recommendation(item_id, Dictionary(inventory[item_id]))

func get_item_compare_summary_for_test(item_id: String) -> Dictionary:
	var inventory: Dictionary = InventoryDataServiceScript.normalize_inventory(player_data.get("inventory", {}))
	if not inventory.has(item_id):
		return {}
	var entry: Dictionary = Dictionary(inventory[item_id])
	if str(entry.get("type", "")) != "equipment":
		return {}
	return _build_item_compare_summary(item_id, Dictionary(entry.get("equipment", {})))

func get_item_action_hint_for_test(item_id: String) -> Dictionary:
	return _build_item_action_hint(item_id)

func get_basic_attack_upgrade_preview_for_test() -> Dictionary:
	return _build_basic_attack_upgrade_preview()

func get_skill_node_previews_for_test() -> Array:
	return _build_all_skill_node_previews()

func get_selected_skill_node_id() -> String:
	return selected_skill_node_id

func get_equipment_slot_summary_for_test(slot: String) -> Dictionary:
	var equipped: Dictionary = Dictionary(player_data.get("equipped_items", {}))
	var inventory: Dictionary = Dictionary(player_data.get("inventory", {}))
	return _build_equipment_slot_summary(slot, equipped, inventory)

func get_visible_item_ids() -> Array:
	return InventoryQueryServiceScript.query_item_ids(player_data, {"filter_mode": filter_mode, "sort_mode": sort_mode})

func get_inventory_capacity_for_test() -> Dictionary:
	return InventoryDataServiceScript.build_capacity_summary(InventoryDataServiceScript.normalize_inventory(player_data.get("inventory", {})))

func _update_inventory_capacity_title(inventory: Dictionary) -> void:
	if not is_instance_valid(inventory_title_label):
		return
	var capacity: Dictionary = InventoryDataServiceScript.build_capacity_summary(inventory)
	inventory_title_label.text = str(capacity.get("summary_text", "背包 0/40"))
	if bool(capacity.get("pressure", false)):
		inventory_title_label.add_theme_color_override("font_color", DarkArpgUiThemeScript.COLOR_GOLD.lightened(0.18))
	else:
		DarkArpgUiThemeScript.style_title(inventory_title_label, 17)

func set_filter_mode(mode: String) -> void:
	filter_mode = InventoryQueryServiceScript.normalize_filter_mode(mode)
	_sync_filter_button_states()
	refresh()

func toggle_item_lock(item_id: String) -> void:
	_toggle_item_flag(item_id, "locked")

func toggle_item_favorite(item_id: String) -> void:
	_toggle_item_flag(item_id, "favorite")

func toggle_item_junk(item_id: String) -> void:
	_toggle_item_flag(item_id, "junk")

func _toggle_item_flag(item_id: String, flag_id: String) -> void:
	var inventory: Dictionary = InventoryDataServiceScript.normalize_inventory(player_data.get("inventory", {}))
	if not inventory.has(item_id):
		return
	var entry: Dictionary = Dictionary(inventory[item_id])
	var flags: Dictionary = Dictionary(entry.get("binding_flags", {}))
	var next_value := not bool(flags.get(flag_id, entry.get(flag_id, false)))
	flags[flag_id] = next_value
	entry["binding_flags"] = flags
	entry[flag_id] = next_value
	if entry.has("equipment"):
		var equipment: Dictionary = Dictionary(entry.get("equipment", {}))
		equipment[flag_id] = next_value
		entry["equipment"] = equipment
	inventory[item_id] = entry
	player_data["inventory"] = inventory
	player_data_changed.emit(player_data.duplicate(true))
	refresh()

func select_item(item_id: String) -> void:
	var inventory: Dictionary = InventoryDataServiceScript.normalize_inventory(player_data.get("inventory", {}))
	if not inventory.has(item_id):
		clear_selection()
		return
	selected_item_id = item_id
	if is_instance_valid(detail_label):
		detail_label.text = _describe_item(Dictionary(inventory[item_id]))
	_update_selected_actions()
	refresh()

func clear_selection() -> void:
	selected_item_id = ""
	if is_instance_valid(detail_label):
		detail_label.text = "选择一个物品查看详情。"
	_update_selected_actions()
	refresh()

func use_selected_item() -> void:
	if selected_item_id == "":
		return
	var inventory: Dictionary = Dictionary(player_data.get("inventory", {}))
	if not inventory.has(selected_item_id):
		clear_selection()
		return
	var entry: Dictionary = Dictionary(inventory[selected_item_id])
	if str(entry.get("type", "")) != "equipment":
		if is_instance_valid(detail_label):
			detail_label.text = _describe_item(entry)
		_update_selected_actions()
		return
	if EquipmentDataServiceScript.is_equipped_item(player_data, selected_item_id):
		var socket_result := socket_selected_equipment()
		if not bool(socket_result.get("ok", false)) and is_instance_valid(detail_label):
			detail_label.text = "%s\n无法镶嵌：%s" % [_describe_item(entry), str(socket_result.get("reason", "unknown"))]
		return
	var result := EquipmentDataServiceScript.equip_item(player_data, selected_item_id)
	if not bool(result.get("ok", false)):
		if is_instance_valid(detail_label):
			detail_label.text = "%s\n无法装备：%s" % [_describe_item(entry), str(result.get("reason", "unknown"))]
		_update_selected_actions()
		return
	player_data = Dictionary(result.get("player_data", player_data))
	player_data_changed.emit(player_data.duplicate(true))
	refresh()

func socket_selected_equipment() -> Dictionary:
	if selected_item_id == "":
		return {"ok": false, "reason": "no_selection", "player_data": player_data.duplicate(true)}
	var result := player_data.duplicate(true)
	var inventory: Dictionary = InventoryDataServiceScript.normalize_inventory(result.get("inventory", {}))
	if not inventory.has(selected_item_id):
		return {"ok": false, "reason": "missing_equipment", "player_data": result}
	var entry: Dictionary = Dictionary(inventory[selected_item_id])
	if str(entry.get("type", "")) != "equipment":
		return {"ok": false, "reason": "not_equipment", "player_data": result}
	var equipment: Dictionary = Dictionary(entry.get("equipment", {}))
	var preview := _build_socket_preview_for_equipment(equipment)
	if not bool(preview.get("can_socket", false)):
		return {"ok": false, "reason": str(preview.get("reason", "no_socket_gem")), "player_data": result}
	var gem_item_id := str(preview.get("gem_item_id", ""))
	var gem_id := str(preview.get("gem_id", ""))
	var socketed := GemSocketServiceScript.socket_gem(equipment, gem_id)
	if not bool(socketed.get("ok", false)):
		return {"ok": false, "reason": str(socketed.get("reason", "socket_failed")), "player_data": result}
	equipment = Dictionary(socketed.get("equipment", equipment))
	entry["equipment"] = equipment
	inventory[selected_item_id] = entry
	var gem_entry: Dictionary = Dictionary(inventory.get(gem_item_id, {}))
	var amount := int(gem_entry.get("amount", 1)) - 1
	if amount <= 0:
		inventory.erase(gem_item_id)
	else:
		gem_entry["amount"] = amount
		inventory[gem_item_id] = gem_entry
	result["inventory"] = inventory
	player_data = result
	player_data_changed.emit(player_data.duplicate(true))
	refresh()
	return {"ok": true, "gem_id": gem_id, "gem_item_id": gem_item_id, "player_data": player_data.duplicate(true)}

func toggle_selected_lock() -> void:
	if selected_item_id == "":
		return
	toggle_item_lock(selected_item_id)

func toggle_selected_favorite() -> void:
	if selected_item_id == "":
		return
	toggle_item_favorite(selected_item_id)

func toggle_selected_junk() -> void:
	if selected_item_id == "":
		return
	toggle_item_junk(selected_item_id)

func sell_junk_items() -> void:
	_request_junk_action_confirmation("sell")

func salvage_junk_items() -> void:
	_request_junk_action_confirmation("salvage")

func _request_junk_action_confirmation(mode: String) -> void:
	var preview: Dictionary = InventoryItemActionServiceScript.build_junk_action_preview(player_data, mode)
	preview["confirm_text"] = _build_junk_action_confirm_text(preview)
	if not bool(preview.get("can_process", false)):
		pending_junk_action_mode = ""
		pending_junk_action_preview = {}
		if is_instance_valid(detail_label):
			detail_label.text = "没有可处理的废品。\n%s" % str(preview.get("summary_text", ""))
		_update_selected_actions()
		return
	pending_junk_action_mode = str(preview.get("mode", mode))
	pending_junk_action_preview = preview.duplicate(true)
	if is_instance_valid(junk_action_confirm_dialog):
		junk_action_confirm_dialog.title = "分解废品" if pending_junk_action_mode == "salvage" else "出售废品"
		junk_action_confirm_dialog.dialog_text = str(preview.get("confirm_text", ""))
		junk_action_confirm_dialog.popup_centered(Vector2i(420, 220))
	if is_instance_valid(detail_label):
		detail_label.text = str(preview.get("confirm_text", ""))

func _confirm_pending_junk_action() -> void:
	if pending_junk_action_mode == "":
		return
	var mode := pending_junk_action_mode
	pending_junk_action_mode = ""
	pending_junk_action_preview = {}
	_process_junk_items(mode)

func get_pending_junk_action_preview_for_test() -> Dictionary:
	return pending_junk_action_preview.duplicate(true)

func confirm_pending_junk_action_for_test() -> void:
	_confirm_pending_junk_action()

func _build_junk_action_confirm_text(preview: Dictionary) -> String:
	var mode := str(preview.get("mode", "sell"))
	var action_label := "分解" if mode == "salvage" else "出售"
	var reward_text := "+%d 水晶碎片" % int(preview.get("crystal_gain", 0)) if mode == "salvage" else "+%d 金币" % int(preview.get("gold_gain", 0))
	return "%s已标记废品？\n处理 %d 件  保护 %d 件\n获得 %s\n锁定、收藏、已穿戴和不可出售物品会被保留。" % [
		action_label,
		int(preview.get("processed_count", 0)),
		int(preview.get("protected_count", 0)),
		reward_text,
	]

func _process_junk_items(mode: String) -> void:
	var result: Dictionary = InventoryItemActionServiceScript.process_junk_action(player_data, mode)
	if not bool(result.get("ok", false)):
		if is_instance_valid(detail_label):
			var preview: Dictionary = Dictionary(result.get("preview", {}))
			detail_label.text = "没有可处理的废品。\n%s" % str(preview.get("summary_text", ""))
		_update_selected_actions()
		return
	player_data = Dictionary(result.get("player_data", player_data))
	if selected_item_id != "" and not Dictionary(player_data.get("inventory", {})).has(selected_item_id):
		selected_item_id = ""
	if is_instance_valid(detail_label):
		detail_label.text = str(result.get("summary_text", "废品已处理。"))
	player_data_changed.emit(player_data.duplicate(true))
	refresh()

func _cycle_sort_mode() -> void:
	if sort_mode == "type":
		sort_mode = "power"
	elif sort_mode == "power":
		sort_mode = "name"
	else:
		sort_mode = "type"
	var sort_button := find_child("SortInventoryButton", true, false) as Button
	if sort_button != null:
		sort_button.text = "排序：%s" % _sort_mode_label(sort_mode)
	refresh()

func _sync_filter_button_states() -> void:
	for mode in filter_buttons.keys():
		var button := filter_buttons[mode] as Button
		if is_instance_valid(button):
			var selected := str(mode) == filter_mode
			button.button_pressed = selected
			DarkArpgUiThemeScript.style_toggle_button(button, selected)

func _entry_matches_filter(entry: Dictionary) -> bool:
	if filter_mode == "all":
		return true
	var item_type := str(entry.get("type", "item"))
	if filter_mode == "equipment":
		return item_type == "equipment"
	if filter_mode == "material":
		return item_type == "material" or item_type == "currency"
	return true

func _sort_item_ids(a: String, b: String, inventory: Dictionary) -> bool:
	var entry_a: Dictionary = Dictionary(inventory.get(a, {}))
	var entry_b: Dictionary = Dictionary(inventory.get(b, {}))
	var locked_a := bool(entry_a.get("locked", false))
	var locked_b := bool(entry_b.get("locked", false))
	if locked_a != locked_b:
		return locked_a
	if sort_mode == "name":
		return str(entry_a.get("name", a)).naturalnocasecmp_to(str(entry_b.get("name", b))) < 0
	if sort_mode == "power":
		var score_a := _get_entry_score(a, entry_a)
		var score_b := _get_entry_score(b, entry_b)
		if score_a != score_b:
			return score_a > score_b
	var type_a := str(entry_a.get("type", "item"))
	var type_b := str(entry_b.get("type", "item"))
	if type_a != type_b:
		return type_a < type_b
	return str(entry_a.get("name", a)).naturalnocasecmp_to(str(entry_b.get("name", b))) < 0

func _update_stats() -> void:
	var stats := EquipmentDataServiceScript.build_stat_totals(player_data)
	stats_label.text = "属性\n伤害：%d\n生命：%d\n法力：%d\n防御：%d\n暴击：%d" % [
		int(stats.get("attack_damage", 0)),
		int(stats.get("max_health", 0)),
		int(stats.get("max_mana", 0)),
		int(stats.get("defense", 0)),
		int(stats.get("critical_chance", 0)),
	]

func _update_skill_summary() -> void:
	var preview := _build_selected_skill_node_preview()
	if preview.is_empty():
		selected_skill_node_id = PlayerDataServiceScript.BASIC_ATTACK_TRAINING_NODE
		preview = _build_selected_skill_node_preview()
	var skill_points := int(preview.get("skill_points", player_data.get("skill_points", 0)))
	if is_instance_valid(skill_point_summary):
		skill_point_summary.text = "天赋点 %d\n%s\n%s" % [
			skill_points,
			str(preview.get("summary_text", "")),
			str(preview.get("status_text", "")),
		]
	_build_skill_node_list()
	if is_instance_valid(upgrade_selected_skill_button):
		upgrade_selected_skill_button.disabled = not bool(preview.get("can_upgrade", false))
		upgrade_selected_skill_button.tooltip_text = str(preview.get("tooltip_text", ""))
	if is_instance_valid(upgrade_basic_attack_button):
		var basic_preview := _build_basic_attack_upgrade_preview()
		upgrade_basic_attack_button.disabled = not bool(basic_preview.get("can_upgrade", false))
		upgrade_basic_attack_button.tooltip_text = str(basic_preview.get("tooltip_text", ""))

func _on_inventory_item_pressed(item_id: String) -> void:
	select_item(item_id)

func _update_selected_actions() -> void:
	var inventory: Dictionary = Dictionary(player_data.get("inventory", {}))
	if selected_item_id != "" and not inventory.has(selected_item_id):
		selected_item_id = ""
	if not is_instance_valid(equip_selected_button) or not is_instance_valid(lock_selected_button) or not is_instance_valid(favorite_selected_button) or not is_instance_valid(junk_selected_button) or not is_instance_valid(clear_selected_button):
		return
	var has_selection := selected_item_id != "" and inventory.has(selected_item_id)
	equip_selected_button.disabled = true
	lock_selected_button.disabled = not has_selection
	favorite_selected_button.disabled = not has_selection
	junk_selected_button.disabled = not has_selection
	clear_selected_button.disabled = not has_selection
	lock_selected_button.text = "锁定"
	favorite_selected_button.text = "收藏"
	junk_selected_button.text = "废品"
	if not has_selection:
		_update_batch_junk_actions()
		return
	var entry: Dictionary = Dictionary(inventory[selected_item_id])
	var flags: Dictionary = Dictionary(entry.get("binding_flags", {}))
	lock_selected_button.text = "解锁" if bool(flags.get("locked", entry.get("locked", false))) else "锁定"
	favorite_selected_button.text = "取消收藏" if bool(flags.get("favorite", entry.get("favorite", false))) else "收藏"
	junk_selected_button.text = "取消废品" if bool(flags.get("junk", entry.get("junk", false))) else "废品"
	var hint := _build_item_action_hint(selected_item_id)
	if not hint.is_empty():
		equip_selected_button.text = str(hint.get("button_text", "装备"))
		equip_selected_button.disabled = not bool(hint.get("can_equip", false))
	else:
		equip_selected_button.text = "装备"
		equip_selected_button.disabled = str(entry.get("type", "")) != "equipment"
	if str(entry.get("type", "")) == "equipment" and EquipmentDataServiceScript.is_equipped_item(player_data, selected_item_id):
		var equipment: Dictionary = Dictionary(entry.get("equipment", {}))
		var socket_preview := _build_socket_preview_for_equipment(equipment)
		if bool(socket_preview.get("can_socket", false)):
			equip_selected_button.text = "镶嵌"
			equip_selected_button.disabled = false
			equip_selected_button.tooltip_text = "镶嵌%s" % str(socket_preview.get("gem_name", "宝石"))
		else:
			equip_selected_button.text = "已装备"
			equip_selected_button.disabled = true
	_update_batch_junk_actions()

func _update_batch_junk_actions() -> void:
	if not is_instance_valid(sell_junk_button) or not is_instance_valid(salvage_junk_button):
		return
	var sell_preview: Dictionary = InventoryItemActionServiceScript.build_junk_action_preview(player_data, "sell")
	var salvage_preview: Dictionary = InventoryItemActionServiceScript.build_junk_action_preview(player_data, "salvage")
	sell_junk_button.disabled = not bool(sell_preview.get("can_process", false))
	salvage_junk_button.disabled = not bool(salvage_preview.get("can_process", false))
	sell_junk_button.tooltip_text = str(sell_preview.get("summary_text", "出售废品 0"))
	salvage_junk_button.tooltip_text = str(salvage_preview.get("summary_text", "分解废品 0"))

func _sync_selected_detail() -> void:
	var inventory: Dictionary = Dictionary(player_data.get("inventory", {}))
	if selected_item_id != "" and not inventory.has(selected_item_id):
		selected_item_id = ""
	if is_instance_valid(detail_label):
		if selected_item_id != "" and inventory.has(selected_item_id):
			detail_label.text = _describe_item(Dictionary(inventory[selected_item_id]))
		elif detail_label.text == "":
			detail_label.text = "选择一个物品查看详情。"
	_update_selected_actions()

func _get_entry_score(item_id: String, entry: Dictionary) -> int:
	if str(entry.get("type", "")) != "equipment":
		return 0
	return EquipmentDataServiceScript.get_item_score(player_data, item_id)

func _get_total_equipment_score() -> int:
	var total := 0
	var equipped: Dictionary = Dictionary(player_data.get("equipped_items", {}))
	for slot in GameConstantsScript.EQUIPMENT_SLOTS:
		var item_id := str(equipped.get(slot, ""))
		total += EquipmentDataServiceScript.get_item_score(player_data, item_id)
	return total

func _build_equipment_slot_summary(slot: String, equipped: Dictionary, inventory: Dictionary) -> Dictionary:
	var item_id := str(equipped.get(slot, ""))
	var summary := {
		"slot": slot,
		"slot_label": _slot_label(slot),
		"item_id": item_id,
		"item_name": "",
		"empty": item_id == "" or not inventory.has(item_id),
		"score": 0,
		"rarity": "empty",
		"button_text": "%s：空" % _slot_label(slot),
		"tooltip": "%s槽位为空" % _slot_label(slot),
	}
	if bool(summary["empty"]):
		return summary
	var entry: Dictionary = Dictionary(inventory[item_id])
	var equipment: Dictionary = Dictionary(entry.get("equipment", {}))
	var score := EquipmentDataServiceScript.get_item_score(player_data, item_id)
	summary["item_name"] = str(entry.get("name", item_id))
	summary["score"] = score
	summary["rarity"] = str(equipment.get("rarity", "common"))
	summary["button_text"] = "%s：%s\n评分 %d" % [_slot_label(slot), str(summary["item_name"]), score]
	summary["tooltip"] = _describe_item(entry)
	return summary

func _build_item_visual_metadata(item_id: String, entry: Dictionary) -> Dictionary:
	var item_type := str(entry.get("type", "item"))
	var rarity := "common"
	var label := _item_short_text(entry)
	var equipped := EquipmentDataServiceScript.is_equipped_item(player_data, item_id)
	var upgrade := false
	var recommendation: Dictionary = {}
	if item_type == "equipment":
		var equipment: Dictionary = Dictionary(entry.get("equipment", {}))
		rarity = str(equipment.get("rarity", "common"))
		var slot_label := _slot_short_label(str(equipment.get("slot", "")))
		label = slot_label
		recommendation = _build_item_recommendation(item_id, entry)
		upgrade = bool(recommendation.get("upgrade", EquipmentDataServiceScript.is_upgrade_candidate(player_data, item_id)))
	else:
		rarity = "currency" if item_type == "currency" else "material"
	var badge := ""
	if equipped:
		badge = "E"
	elif upgrade:
		badge = "+"
	if badge != "":
		label = "%s\n%s" % [badge, label]
	return {
		"item_id": item_id,
		"type": item_type,
		"rarity": rarity,
		"label": label,
		"badge": badge,
		"equipped": equipped,
		"upgrade": upgrade,
		"score": int(recommendation.get("score", 0)),
		"equipped_score": int(recommendation.get("equipped_score", 0)),
		"score_delta": int(recommendation.get("score_delta", 0)),
		"recommendation_rank": str(recommendation.get("recommendation_rank", "")),
		"recommendation_text": str(recommendation.get("recommendation_text", "")),
		"source_label": str(recommendation.get("source_label", "")),
		"quality_tag": str(recommendation.get("quality_tag", "")),
		"border_color": _rarity_border_color_hex(rarity),
		"background_color": _rarity_background_color_hex(rarity),
	}

func _build_item_recommendation(item_id: String, entry: Dictionary) -> Dictionary:
	if str(entry.get("type", "")) != "equipment":
		return {}
	var equipment: Dictionary = Dictionary(entry.get("equipment", {})).duplicate(true)
	if equipment.is_empty():
		return {}
	if str(equipment.get("instance_id", "")) == "":
		equipment["instance_id"] = item_id
	var loot_quality: Dictionary = Dictionary(entry.get("loot_quality", {})).duplicate(true)
	if not loot_quality.has("source") and entry.has("source"):
		loot_quality["source"] = str(entry.get("source", "normal"))
	return EquipmentRecommendationServiceScript.build_recommendation(player_data, equipment, loot_quality)

func _build_item_action_hint(item_id: String) -> Dictionary:
	return EquipmentActionHintServiceScript.build_hint(player_data, item_id)

func _build_basic_attack_upgrade_preview() -> Dictionary:
	return SkillUpgradePreviewServiceScript.build_basic_attack_preview(player_data)

func _build_all_skill_node_previews() -> Array:
	return SkillUpgradePreviewServiceScript.build_all_previews(player_data)

func _build_selected_skill_node_preview() -> Dictionary:
	return SkillNodeGrowthServiceScript.build_preview(player_data, selected_skill_node_id)

func _build_skill_node_list() -> void:
	if not is_instance_valid(skill_node_list):
		return
	for child in skill_node_list.get_children():
		skill_node_list.remove_child(child)
		child.free()
	for preview in _build_all_skill_node_previews():
		var data: Dictionary = Dictionary(preview)
		var node_id := str(data.get("node_id", ""))
		if node_id == "":
			continue
		var button := Button.new()
		button.name = "SkillNode%s" % _skill_node_suffix(node_id)
		button.custom_minimum_size = Vector2(200, 32)
		var selected_prefix := "* " if node_id == selected_skill_node_id else ""
		button.text = "%s%s 等级%d/%d" % [
			selected_prefix,
			str(data.get("title", node_id)),
			int(data.get("current_level", 0)),
			int(data.get("max_level", 1)),
		]
		button.tooltip_text = str(data.get("tooltip_text", ""))
		button.disabled = false
		DarkArpgUiThemeScript.style_toggle_button(button, node_id == selected_skill_node_id)
		button.pressed.connect(select_skill_node.bind(node_id))
		skill_node_list.add_child(button)

func _skill_node_suffix(node_id: String) -> String:
	var parts := node_id.split("_")
	var result := ""
	for part in parts:
		var text := str(part)
		if text == "":
			continue
		result += text.substr(0, 1).to_upper() + text.substr(1)
	return result

func _build_item_compare_summary(item_id: String, candidate_equipment: Dictionary) -> Dictionary:
	if str(candidate_equipment.get("slot", "")) == "":
		return {}
	var candidate_id := item_id
	if candidate_id == "":
		candidate_id = str(candidate_equipment.get("instance_id", "candidate"))
	return EquipmentCompareSummaryServiceScript.build_summary(player_data, candidate_id, candidate_equipment)

func _apply_item_button_style(button: Button, visual_meta: Dictionary) -> void:
	var normal := StyleBoxFlat.new()
	var rarity := str(visual_meta.get("rarity", "common"))
	normal.bg_color = DarkArpgUiThemeScript.rarity_background_color(rarity)
	normal.border_color = DarkArpgUiThemeScript.rarity_border_color(rarity)
	normal.set_border_width_all(2)
	normal.corner_radius_top_left = 2
	normal.corner_radius_top_right = 2
	normal.corner_radius_bottom_left = 2
	normal.corner_radius_bottom_right = 2
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = hover.bg_color.lightened(0.08)
	button.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = pressed.bg_color.darkened(0.08)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", DarkArpgUiThemeScript.make_button_box(false, false, false, true))
	button.add_theme_color_override("font_color", DarkArpgUiThemeScript.COLOR_BONE)
	button.add_theme_font_size_override("font_size", 14)
	if bool(visual_meta.get("upgrade", false)):
		button.add_theme_color_override("font_color", Color(0.82, 1.0, 0.68))
	elif bool(visual_meta.get("equipped", false)):
		button.add_theme_color_override("font_color", DarkArpgUiThemeScript.COLOR_GOLD.lightened(0.12))

func _rarity_border_color_hex(rarity: String) -> String:
	return DarkArpgUiThemeScript.rarity_border_color(rarity).to_html(false)

func _rarity_background_color_hex(rarity: String) -> String:
	return DarkArpgUiThemeScript.rarity_background_color(rarity).to_html(false)

func _slot_label(slot: String) -> String:
	match slot:
		"weapon":
			return "武器"
		"armor":
			return "护甲"
		"ring":
			return "戒指"
		_:
			return slot.capitalize() if slot != "" else "未知"

func _slot_short_label(slot: String) -> String:
	match slot:
		"weapon":
			return "武"
		"armor":
			return "甲"
		"ring":
			return "戒"
		_:
			return slot.substr(0, 1).to_upper() if slot != "" else "?"

func _item_type_label(item_type: String) -> String:
	match item_type:
		"equipment":
			return "装备"
		"material":
			return "材料"
		"currency":
			return "货币"
		"gem":
			return "宝石"
		_:
			return "物品"

func _rarity_label(rarity: String) -> String:
	match rarity:
		"magic":
			return "魔法"
		"rare":
			return "稀有"
		"legendary":
			return "传奇"
		"empty":
			return "空"
		_:
			return "普通"

func _sort_mode_label(mode: String) -> String:
	match mode:
		"power":
			return "强度"
		"name":
			return "名称"
		_:
			return "类型"

func _stat_label(stat_id: String) -> String:
	match stat_id:
		"attack_damage":
			return "伤害"
		"max_health":
			return "生命"
		"max_mana":
			return "法力"
		"defense":
			return "防御"
		"critical_chance":
			return "暴击"
		"attack_speed":
			return "攻击速度"
		"projectile_count":
			return "投射物数量"
		"cold_damage":
			return "冰冷伤害"
		"ice_lance_pierce":
			return "冰矢穿透"
		"ice_lance_split":
			return "冰矢分裂"
		"coc_cooldown_recovery":
			return "触发恢复"
		"mana":
			return "法力"
		"summon_damage":
			return "召唤伤害"
		_:
			return stat_id

func _build_socket_preview_for_equipment(equipment: Dictionary) -> Dictionary:
	var limit := GemSocketServiceScript.get_socket_limit(str(equipment.get("slot", "")))
	if limit <= 0:
		return {"can_socket": false, "reason": "no_socket"}
	var socketed := GemSocketServiceScript.normalize_socketed_gems(equipment)
	if socketed.size() >= limit:
		return {"can_socket": false, "reason": "socket_full"}
	var inventory: Dictionary = InventoryDataServiceScript.normalize_inventory(player_data.get("inventory", {}))
	var gem_item_id := _find_first_socketable_gem_item_id(inventory, equipment)
	if gem_item_id == "":
		return {"can_socket": false, "reason": "no_gem"}
	var gem_entry: Dictionary = Dictionary(inventory[gem_item_id])
	var gem_id := _get_entry_gem_id(gem_entry)
	return {
		"can_socket": true,
		"gem_item_id": gem_item_id,
		"gem_id": gem_id,
		"gem_name": GemSocketServiceScript.get_gem_name(gem_id),
	}

func _find_first_socketable_gem_item_id(inventory: Dictionary, equipment: Dictionary) -> String:
	var ids: Array[String] = []
	for item_id in inventory.keys():
		ids.append(str(item_id))
	ids.sort()
	for item_id in ids:
		var entry: Dictionary = Dictionary(inventory[item_id])
		if not _is_gem_entry(entry):
			continue
		var gem_id := _get_entry_gem_id(entry)
		if bool(GemSocketServiceScript.socket_gem(equipment, gem_id).get("ok", false)):
			return item_id
	return ""

func _is_gem_entry(entry: Dictionary) -> bool:
	if str(entry.get("type", "")) == "gem":
		return true
	return str(entry.get("gem_id", "")) != ""

func _get_entry_gem_id(entry: Dictionary) -> String:
	var gem_id := str(entry.get("gem_id", ""))
	if gem_id != "":
		return gem_id
	return str(entry.get("id", ""))

func get_ui_style_id_for_test() -> String:
	return DarkArpgUiThemeScript.get_style_id()

func _on_equipment_slot_pressed(slot: String) -> void:
	var result := EquipmentDataServiceScript.unequip_slot(player_data, slot)
	if not bool(result.get("ok", false)):
		return
	player_data = Dictionary(result.get("player_data", player_data))
	player_data_changed.emit(player_data.duplicate(true))
	refresh()

func _on_upgrade_basic_attack_pressed() -> void:
	var result := PlayerDataServiceScript.upgrade_basic_attack(player_data)
	if not bool(result.get("ok", false)):
		if is_instance_valid(detail_label):
			detail_label.text = "无法升级：%s" % str(result.get("reason", "unknown"))
		refresh()
		return
	player_data = Dictionary(result.get("player_data", player_data))
	if is_instance_valid(detail_label):
		detail_label.text = "基础攻击训练 等级%d\n伤害 +%d" % [
			int(result.get("node_level", 0)),
			PlayerDataServiceScript.BASIC_ATTACK_TRAINING_DAMAGE_GAIN,
		]
	player_data_changed.emit(player_data.duplicate(true))
	refresh()

func select_skill_node(node_id: String) -> void:
	if SkillNodeGrowthServiceScript.get_node(node_id).is_empty():
		return
	selected_skill_node_id = node_id
	_update_skill_summary()

func upgrade_selected_skill_node() -> void:
	var result := SkillNodeGrowthServiceScript.upgrade_node(player_data, selected_skill_node_id)
	if not bool(result.get("ok", false)):
		if is_instance_valid(detail_label):
			detail_label.text = "无法升级：%s" % str(result.get("reason", "unknown"))
		refresh()
		return
	player_data = Dictionary(result.get("player_data", player_data))
	if is_instance_valid(detail_label):
		detail_label.text = "%s 等级%d\n%s +%d" % [
			str(_build_selected_skill_node_preview().get("title", selected_skill_node_id)),
			int(result.get("node_level", 0)),
			str(_build_selected_skill_node_preview().get("stat_label", result.get("stat_id", ""))),
			int(result.get("stat_gain", 0)),
		]
	player_data_changed.emit(player_data.duplicate(true))
	refresh()
