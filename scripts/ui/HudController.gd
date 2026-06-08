extends CanvasLayer
class_name HudController

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
	status_label = _make_label("StatusLabel", Vector2(20, 18), 20, Color(1.0, 0.78, 0.34))
	log_label = _make_label("LogLabel", Vector2(20, 54), 15, Color(0.9, 0.78, 0.56))
	health_label = _make_label("HealthLabel", Vector2(20, 86), 15, Color(1.0, 0.42, 0.38))
	health_bar = _make_bar("HealthBar", Vector2(88, 90), Vector2(190, 12), Color(0.72, 0.08, 0.06))
	mana_label = _make_label("ManaLabel", Vector2(20, 108), 15, Color(0.38, 0.68, 1.0))
	mana_bar = _make_bar("ManaBar", Vector2(88, 112), Vector2(190, 12), Color(0.08, 0.28, 0.78))
	level_label = _make_label("LevelLabel", Vector2(20, 136), 16, Color(0.82, 0.93, 1.0))
	experience_bar = ProgressBar.new()
	experience_bar.name = "ExperienceBar"
	experience_bar.position = Vector2(20, 164)
	experience_bar.size = Vector2(260, 14)
	experience_bar.min_value = 0
	experience_bar.max_value = 100
	experience_bar.value = 0
	experience_bar.show_percentage = false
	skill_point_label = _make_label("SkillPointLabel", Vector2(290, 154), 14, Color(0.78, 0.94, 0.78))
	inventory_label = _make_label("InventoryLabel", Vector2(960, 18), 16, Color(0.72, 0.9, 1.0))
	loot_notification_label = _make_label("LootNotificationLabel", Vector2(860, 54), 15, Color(0.92, 0.95, 1.0))
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
	label.add_theme_font_size_override("font_size", font_size)
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
	bar.add_theme_color_override("font_color", Color.TRANSPARENT)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	bar.add_theme_stylebox_override("fill", fill)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.05, 0.06, 0.07, 0.86)
	bar.add_theme_stylebox_override("background", background)
	return bar
