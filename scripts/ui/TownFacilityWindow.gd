extends Control
class_name TownFacilityWindow

signal close_requested
signal action_requested(facility_id: String, action_id: String)

const TownFacilityServiceScript := preload("res://scripts/data/TownFacilityService.gd")
const DarkArpgUiThemeScript := preload("res://scripts/ui/DarkArpgUiTheme.gd")

var facility_id := ""
var title_label: Label
var subtitle_label: Label
var description_label: Label
var action_box: VBoxContainer

func _ready() -> void:
	_build_ui()
	visible = false

func open_facility(id: String) -> void:
	var config := TownFacilityServiceScript.get_facility_config(id)
	if config.is_empty():
		return
	facility_id = id
	visible = true
	if not is_instance_valid(title_label):
		return
	title_label.text = str(config.get("title", "Facility"))
	subtitle_label.text = str(config.get("subtitle", ""))
	description_label.text = str(config.get("description", ""))
	_rebuild_actions(Array(config.get("actions", [])))

func close() -> void:
	visible = false

func get_open_facility_id() -> String:
	return facility_id if visible else ""

func trigger_action_for_test(action_id: String) -> void:
	_on_action_pressed(action_id)

func _build_ui() -> void:
	name = "TownFacilityWindow"
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	size = Vector2(430, 360)
	position = Vector2(238, 178)

	var panel := PanelContainer.new()
	panel.name = "TownFacilityPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	DarkArpgUiThemeScript.style_panel(panel, true)
	add_child(panel)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 8)
	panel.add_child(root_box)

	var header := HBoxContainer.new()
	root_box.add_child(header)

	title_label = Label.new()
	title_label.name = "TownFacilityTitle"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DarkArpgUiThemeScript.style_title(title_label, 22)
	header.add_child(title_label)

	var close_button := Button.new()
	close_button.name = "CloseTownFacilityButton"
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(36, 32)
	DarkArpgUiThemeScript.style_button(close_button)
	close_button.pressed.connect(func():
		close()
		close_requested.emit()
	)
	header.add_child(close_button)

	subtitle_label = Label.new()
	subtitle_label.name = "TownFacilitySubtitle"
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.custom_minimum_size = Vector2(390, 34)
	DarkArpgUiThemeScript.style_body_label(subtitle_label, 15, true)
	root_box.add_child(subtitle_label)

	description_label = Label.new()
	description_label.name = "TownFacilityDescription"
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.custom_minimum_size = Vector2(390, 84)
	DarkArpgUiThemeScript.style_body_label(description_label, 15)
	root_box.add_child(description_label)

	action_box = VBoxContainer.new()
	action_box.name = "TownFacilityActions"
	action_box.add_theme_constant_override("separation", 6)
	root_box.add_child(action_box)

func _rebuild_actions(actions: Array) -> void:
	if not is_instance_valid(action_box):
		return
	for child in action_box.get_children():
		child.queue_free()
	for action in actions:
		var action_data := Dictionary(action)
		var button := Button.new()
		button.name = "TownFacilityAction_%s" % str(action_data.get("id", "action"))
		button.text = str(action_data.get("label", "Action"))
		button.custom_minimum_size = Vector2(390, 38)
		DarkArpgUiThemeScript.style_button(button, bool(action_data.get("primary", false)))
		var action_id := str(action_data.get("id", ""))
		button.pressed.connect(func(): _on_action_pressed(action_id))
		action_box.add_child(button)

func _on_action_pressed(action_id: String) -> void:
	if facility_id == "" or action_id == "":
		return
	action_requested.emit(facility_id, action_id)
