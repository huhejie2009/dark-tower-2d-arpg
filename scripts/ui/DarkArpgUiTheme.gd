extends RefCounted
class_name DarkArpgUiTheme

const STYLE_ID := "dark_tower_brutalist_arpg_ui_v1"

const COLOR_VOID := Color(0.015, 0.014, 0.016, 0.96)
const COLOR_PANEL := Color(0.065, 0.058, 0.052, 0.94)
const COLOR_PANEL_RAISED := Color(0.105, 0.092, 0.078, 0.96)
const COLOR_IRON := Color(0.18, 0.17, 0.16, 1.0)
const COLOR_IRON_HOVER := Color(0.25, 0.22, 0.19, 1.0)
const COLOR_BLOOD := Color(0.43, 0.055, 0.045, 1.0)
const COLOR_BLOOD_HOVER := Color(0.57, 0.07, 0.055, 1.0)
const COLOR_BONE := Color(0.86, 0.78, 0.61, 1.0)
const COLOR_MUTED := Color(0.58, 0.52, 0.43, 1.0)
const COLOR_GOLD := Color(0.78, 0.56, 0.25, 1.0)
const COLOR_MANA := Color(0.12, 0.34, 0.68, 1.0)
const COLOR_HEALTH := Color(0.58, 0.03, 0.035, 1.0)
const COLOR_XP := Color(0.52, 0.38, 0.14, 1.0)

static func get_style_id() -> String:
	return STYLE_ID

static func get_palette_for_test() -> Dictionary:
	return {
		"style_id": STYLE_ID,
		"panel": COLOR_PANEL,
		"raised": COLOR_PANEL_RAISED,
		"primary": COLOR_BLOOD,
		"text": COLOR_BONE,
		"muted": COLOR_MUTED,
		"gold": COLOR_GOLD,
		"health": COLOR_HEALTH,
		"mana": COLOR_MANA,
		"xp": COLOR_XP,
	}

static func make_panel_box(raised: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = COLOR_PANEL_RAISED if raised else COLOR_PANEL
	box.border_color = COLOR_GOLD.darkened(0.34)
	box.set_border_width_all(2)
	box.corner_radius_top_left = 2
	box.corner_radius_top_right = 2
	box.corner_radius_bottom_left = 2
	box.corner_radius_bottom_right = 2
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box

static func make_button_box(primary: bool = false, hover: bool = false, pressed: bool = false, selected: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	var base := COLOR_BLOOD if primary else COLOR_IRON
	if selected:
		base = base.lightened(0.12)
	if hover:
		base = COLOR_BLOOD_HOVER if primary else COLOR_IRON_HOVER
	if pressed:
		base = base.darkened(0.18)
	box.bg_color = base
	box.border_color = COLOR_GOLD if selected or primary else COLOR_MUTED.darkened(0.25)
	box.set_border_width_all(2 if selected or primary else 1)
	box.corner_radius_top_left = 2
	box.corner_radius_top_right = 2
	box.corner_radius_bottom_left = 2
	box.corner_radius_bottom_right = 2
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box

static func make_bar_background() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.018, 0.016, 0.015, 0.92)
	box.border_color = COLOR_MUTED.darkened(0.35)
	box.set_border_width_all(1)
	box.corner_radius_top_left = 1
	box.corner_radius_top_right = 1
	box.corner_radius_bottom_left = 1
	box.corner_radius_bottom_right = 1
	return box

static func make_bar_fill(fill_color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill_color
	box.corner_radius_top_left = 1
	box.corner_radius_top_right = 1
	box.corner_radius_bottom_left = 1
	box.corner_radius_bottom_right = 1
	return box

static func style_panel(panel: Control, raised: bool = false) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", make_panel_box(raised))

static func style_button(button: Button, primary: bool = false) -> void:
	if button == null:
		return
	button.add_theme_stylebox_override("normal", make_button_box(primary))
	button.add_theme_stylebox_override("hover", make_button_box(primary, true))
	button.add_theme_stylebox_override("pressed", make_button_box(primary, false, true))
	button.add_theme_stylebox_override("focus", make_button_box(primary, false, false, true))
	button.add_theme_stylebox_override("disabled", make_disabled_button_box())
	button.add_theme_color_override("font_color", COLOR_BONE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", COLOR_GOLD.lightened(0.18))
	button.add_theme_color_override("font_disabled_color", COLOR_MUTED.darkened(0.18))
	button.add_theme_font_size_override("font_size", 15)

static func style_toggle_button(button: Button, selected: bool = false) -> void:
	if button == null:
		return
	style_button(button, false)
	button.add_theme_stylebox_override("pressed", make_button_box(false, false, false, true))
	if selected:
		button.add_theme_stylebox_override("normal", make_button_box(false, false, false, true))
		button.add_theme_color_override("font_color", COLOR_GOLD.lightened(0.12))

static func style_title(label: Label, font_size: int = 28) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", COLOR_BONE)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)

static func style_body_label(label: Label, font_size: int = 15, muted: bool = false) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", COLOR_MUTED if muted else COLOR_BONE)

static func style_bar(bar: ProgressBar, fill_color: Color) -> void:
	if bar == null:
		return
	bar.add_theme_color_override("font_color", Color.TRANSPARENT)
	bar.add_theme_stylebox_override("background", make_bar_background())
	bar.add_theme_stylebox_override("fill", make_bar_fill(fill_color))

static func make_disabled_button_box() -> StyleBoxFlat:
	var box := make_button_box(false)
	box.bg_color = Color(0.08, 0.075, 0.07, 0.82)
	box.border_color = Color(0.18, 0.16, 0.14, 0.78)
	return box

static func rarity_border_color(rarity: String) -> Color:
	match rarity:
		"magic":
			return Color(0.25, 0.48, 0.86, 1.0)
		"rare":
			return Color(0.84, 0.66, 0.24, 1.0)
		"legendary":
			return Color(0.76, 0.34, 0.12, 1.0)
		"currency":
			return Color(0.78, 0.56, 0.25, 1.0)
		"material":
			return Color(0.38, 0.38, 0.36, 1.0)
		_:
			return Color(0.56, 0.53, 0.48, 1.0)

static func rarity_background_color(rarity: String) -> Color:
	match rarity:
		"magic":
			return Color(0.07, 0.12, 0.20, 0.96)
		"rare":
			return Color(0.18, 0.14, 0.06, 0.96)
		"legendary":
			return Color(0.22, 0.10, 0.055, 0.96)
		"currency":
			return Color(0.17, 0.13, 0.055, 0.96)
		"material":
			return Color(0.11, 0.12, 0.12, 0.96)
		_:
			return Color(0.12, 0.115, 0.105, 0.96)
