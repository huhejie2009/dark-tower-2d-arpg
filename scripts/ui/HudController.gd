extends CanvasLayer
class_name HudController

const DarkArpgUiThemeScript := preload("res://scripts/ui/DarkArpgUiTheme.gd")

var hud_panel: PanelContainer
var status_label: Label
var log_label: Label
var health_label: Label
var health_bar: ProgressBar
var mana_label: Label
var mana_bar: ProgressBar
var inventory_label: Label
var level_label: Label
var experience_bar: ProgressBar
var skill_point_label: Label
var loot_notification_label: Label
var last_loot_notification: Dictionary = {}

func _ready() -> void:
	name = "HudController"
	hud_panel = PanelContainer.new()
	hud_panel.name = "DarkArpgHudPanel"
	hud_panel.position = Vector2(14, 14)
	hud_panel.size = Vector2(292, 184)
	DarkArpgUiThemeScript.style_panel(hud_panel)
	add_child(hud_panel)

	status_label = _make_label("StatusLabel", Vector2(20, 18), 20, DarkArpgUiThemeScript.COLOR_GOLD)
	log_label = _make_label("LogLabel", Vector2(20, 54), 15, DarkArpgUiThemeScript.COLOR_BONE)
	health_label = _make_label("HealthLabel", Vector2(20, 86), 15, DarkArpgUiThemeScript.COLOR_BONE)
	health_bar = _make_bar("HealthBar", Vector2(88, 90), Vector2(190, 12), DarkArpgUiThemeScript.COLOR_HEALTH)
	mana_label = _make_label("ManaLabel", Vector2(20, 108), 15, DarkArpgUiThemeScript.COLOR_BONE)
	mana_bar = _make_bar("ManaBar", Vector2(88, 112), Vector2(190, 12), DarkArpgUiThemeScript.COLOR_MANA)
	level_label = _make_label("LevelLabel", Vector2(20, 136), 16, DarkArpgUiThemeScript.COLOR_BONE)
	experience_bar = ProgressBar.new()
	experience_bar.name = "ExperienceBar"
	experience_bar.position = Vector2(20, 164)
	experience_bar.size = Vector2(260, 14)
	experience_bar.min_value = 0
	experience_bar.max_value = 100
	experience_bar.value = 0
	experience_bar.show_percentage = false
	DarkArpgUiThemeScript.style_bar(experience_bar, DarkArpgUiThemeScript.COLOR_XP)
	skill_point_label = _make_label("SkillPointLabel", Vector2(290, 154), 14, DarkArpgUiThemeScript.COLOR_GOLD)
	inventory_label = _make_label("InventoryLabel", Vector2(960, 18), 16, DarkArpgUiThemeScript.COLOR_BONE)
	loot_notification_label = _make_label("LootNotificationLabel", Vector2(860, 54), 15, DarkArpgUiThemeScript.COLOR_BONE)
	loot_notification_label.size = Vector2(380, 110)
	loot_notification_label.visible = false
	add_child(status_label)
	add_child(log_label)
	add_child(health_label)
	add_child(health_bar)
	add_child(mana_label)
	add_child(mana_bar)
	add_child(level_label)
	add_child(experience_bar)
	add_child(skill_point_label)
	add_child(inventory_label)
	add_child(loot_notification_label)
	_sync_layout_to_viewport()
	get_viewport().size_changed.connect(_sync_layout_to_viewport)

func set_status(text: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = text

func set_log(text: String) -> void:
	if is_instance_valid(log_label):
		log_label.text = text

func set_inventory(text: String) -> void:
	if is_instance_valid(inventory_label):
		inventory_label.text = text

func set_player_vitals(health: int, max_health: int, mana: int, max_mana: int) -> void:
	var safe_max_health := maxi(1, max_health)
	var safe_health := clampi(health, 0, safe_max_health)
	var safe_max_mana := maxi(1, max_mana)
	var safe_mana := clampi(mana, 0, safe_max_mana)
	if is_instance_valid(health_label):
		health_label.text = "HP %d/%d" % [safe_health, safe_max_health]
	if is_instance_valid(health_bar):
		health_bar.max_value = safe_max_health
		health_bar.value = safe_health
	if is_instance_valid(mana_label):
		mana_label.text = "MP %d/%d" % [safe_mana, safe_max_mana]
	if is_instance_valid(mana_bar):
		mana_bar.max_value = safe_max_mana
		mana_bar.value = safe_mana

func set_player_progress(level: int, current_exp: int, exp_to_next_level: int, skill_points: int) -> void:
	var safe_level := maxi(1, level)
	var safe_next := maxi(1, exp_to_next_level)
	var safe_current := clampi(current_exp, 0, safe_next)
	if is_instance_valid(level_label):
		level_label.text = "Lv.%d  XP %d/%d" % [safe_level, safe_current, safe_next]
	if is_instance_valid(experience_bar):
		experience_bar.max_value = safe_next
		experience_bar.value = safe_current
	if is_instance_valid(skill_point_label):
		skill_point_label.text = "SP %d" % maxi(0, skill_points)

func show_loot_notification(notification: Dictionary) -> void:
	last_loot_notification = notification.duplicate(true)
	if not is_instance_valid(loot_notification_label):
		return
	var headline := str(notification.get("headline", "Loot acquired"))
	var item_name := str(notification.get("item_name", "Item"))
	var rarity := str(notification.get("rarity", "common")).capitalize()
	var score := int(notification.get("score", 0))
	var short_tag := str(notification.get("short_tag", notification.get("source_label", "")))
	var recommendation := str(notification.get("recommendation_text", ""))
	var upgrade_text := "  +" if bool(notification.get("upgrade", false)) else ""
	var score_text := "\nScore %d" % score if score > 0 else ""
	var tag_text := "%s\n" % short_tag if short_tag != "" else ""
	var recommendation_text := "\n%s" % recommendation if recommendation != "" and not short_tag.contains(recommendation) else ""
	loot_notification_label.text = "%s%s\n%s%s\n%s%s%s" % [headline, upgrade_text, tag_text, item_name, rarity, score_text, recommendation_text]
	loot_notification_label.visible = true
	var accent := Color.html(str(notification.get("accent_color", "#9ca3af")))
	loot_notification_label.add_theme_color_override("font_color", accent)

func get_last_loot_notification_for_test() -> Dictionary:
	return last_loot_notification.duplicate(true)

func _make_label(label_name: String, pos: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = label_name
	label.position = pos
	label.size = Vector2(300, 80)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	DarkArpgUiThemeScript.style_body_label(label, font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _make_bar(bar_name: String, pos: Vector2, bar_size: Vector2, fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.name = bar_name
	bar.position = pos
	bar.size = bar_size
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 0
	bar.show_percentage = false
	DarkArpgUiThemeScript.style_bar(bar, fill_color)
	return bar

func get_ui_style_id_for_test() -> String:
	return DarkArpgUiThemeScript.get_style_id()

func _sync_layout_to_viewport() -> void:
	var viewport_size := Vector2(get_viewport().get_visible_rect().size)
	var rects := get_visual_qa_rects_for_test(viewport_size)
	if is_instance_valid(inventory_label):
		var inventory_rect: Rect2 = Rect2(rects.get("inventory", Rect2()))
		inventory_label.position = inventory_rect.position
		inventory_label.size = inventory_rect.size
	if is_instance_valid(loot_notification_label):
		var loot_rect: Rect2 = Rect2(rects.get("loot", Rect2()))
		loot_notification_label.position = loot_rect.position
		loot_notification_label.size = loot_rect.size

func get_visual_qa_rects_for_test(viewport_size: Vector2) -> Dictionary:
	var safe_width := maxf(360.0, viewport_size.x)
	var inventory_size := Vector2(minf(300.0, safe_width - 28.0), 42.0)
	var inventory_x := maxf(14.0, safe_width - inventory_size.x - 20.0)
	var loot_size := Vector2(minf(380.0, safe_width - 28.0), 110.0)
	var loot_x := maxf(14.0, safe_width - loot_size.x - 20.0)
	return {
		"inventory": Rect2(Vector2(inventory_x, 18.0), inventory_size),
		"loot": Rect2(Vector2(loot_x, 64.0), loot_size),
	}
