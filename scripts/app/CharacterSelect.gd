extends Control

const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")
const SaveSchemaScript := preload("res://scripts/save/SaveSchema.gd")
const SceneRouterScript := preload("res://scripts/app/SceneRouter.gd")
const ClassRulesScript := preload("res://scripts/rules/ClassRules.gd")

var selected_class: String = "warrior"
var selected_slot_id: String = "slot_1"
var save_data: Dictionary = {}
var selected_slot_summary: Label
var selected_class_summary: Label

func _ready() -> void:
	save_data = SaveManagerScript.load_save()
	_build_ui()

func _build_ui() -> void:
	var title := Label.new()
	title.text = "Choose Hero Slot"
	title.position = Vector2(480, 70)
	title.add_theme_font_size_override("font_size", 34)
	add_child(title)

	var slots: Dictionary = Dictionary(save_data.get("slots", {}))
	for i in range(SaveSchemaScript.SLOT_IDS.size()):
		var slot_id: String = SaveSchemaScript.SLOT_IDS[i]
		var slot: Dictionary = Dictionary(slots.get(slot_id, SaveSchemaScript.empty_slot(slot_id)))
		var button := Button.new()
		button.name = "SlotButton%s" % slot_id.capitalize()
		button.position = Vector2(250 + i * 270, 145)
		button.size = Vector2(230, 120)
		button.text = _build_slot_text(slot)
		button.pressed.connect(_on_slot_pressed.bind(slot_id))
		add_child(button)

	var class_title := Label.new()
	class_title.text = "Class for empty slot"
	class_title.position = Vector2(520, 310)
	class_title.add_theme_font_size_override("font_size", 20)
	add_child(class_title)

	var classes: Array[String] = ["warrior", "ranger", "mage", "acolyte"]
	for i in range(classes.size()):
		var class_id: String = classes[i]
		var button := Button.new()
		button.name = "ClassButton%s" % class_id.capitalize()
		button.text = ClassRulesScript.get_class_name(class_id)
		button.position = Vector2(360 + i * 130, 350)
		button.size = Vector2(112, 46)
		button.pressed.connect(_select_class.bind(class_id))
		add_child(button)

	selected_slot_summary = Label.new()
	selected_slot_summary.name = "SelectedSlotSummary"
	selected_slot_summary.position = Vector2(430, 410)
	selected_slot_summary.size = Vector2(420, 28)
	selected_slot_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selected_slot_summary.add_theme_font_size_override("font_size", 16)
	add_child(selected_slot_summary)

	selected_class_summary = Label.new()
	selected_class_summary.name = "SelectedClassSummary"
	selected_class_summary.position = Vector2(430, 438)
	selected_class_summary.size = Vector2(420, 28)
	selected_class_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selected_class_summary.add_theme_font_size_override("font_size", 16)
	add_child(selected_class_summary)

	var create := Button.new()
	create.name = "CreateCharacterButton"
	create.text = "Create In Selected Empty Slot"
	create.position = Vector2(480, 490)
	create.size = Vector2(280, 54)
	create.pressed.connect(_create_character)
	add_child(create)
	_update_selection_summary()

func _build_slot_text(slot: Dictionary) -> String:
	var label := str(slot.get("slot_id", "slot"))
	if not bool(slot.get("exists", false)):
		return "%s\nEmpty\nClick to select" % label
	return "%s\n%s\n%s Lv.%d | Floor %d" % [
		label,
		str(slot.get("character_name", "Hero")),
		ClassRulesScript.get_class_name(str(slot.get("base_class", "warrior"))),
		int(slot.get("player_level", 1)),
		int(slot.get("highest_floor", 1)),
	]

func _on_slot_pressed(slot_id: String) -> void:
	selected_slot_id = slot_id
	var slot: Dictionary = Dictionary(Dictionary(save_data.get("slots", {})).get(slot_id, {}))
	if bool(slot.get("exists", false)):
		SaveManagerScript.set_active_slot(slot_id)
		SceneRouterScript.go_to_town(get_tree())
		return
	_update_selection_summary()

func _select_class(class_id: String) -> void:
	selected_class = class_id
	_update_selection_summary()

func _update_selection_summary() -> void:
	if is_instance_valid(selected_slot_summary):
		selected_slot_summary.text = "Selected Slot: %s" % selected_slot_id
	if is_instance_valid(selected_class_summary):
		selected_class_summary.text = "Selected Class: %s (%s)" % [ClassRulesScript.get_class_name(selected_class), selected_class]

func _create_character() -> void:
	var slot: Dictionary = Dictionary(Dictionary(save_data.get("slots", {})).get(selected_slot_id, {}))
	if bool(slot.get("exists", false)):
		SaveManagerScript.set_active_slot(selected_slot_id)
		SceneRouterScript.go_to_town(get_tree())
		return
	SaveManagerScript.create_character(selected_slot_id, "New Hero", selected_class)
	SceneRouterScript.go_to_town(get_tree())
