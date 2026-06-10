extends Control
class_name StashWindow

signal player_data_changed(player_data: Dictionary)
signal stash_changed(stash: Dictionary)
signal close_requested

const InventoryDataServiceScript := preload("res://scripts/data/InventoryDataService.gd")
const StashStorageServiceScript := preload("res://scripts/data/StashStorageService.gd")
const DarkArpgUiThemeScript := preload("res://scripts/ui/DarkArpgUiTheme.gd")

var player_data: Dictionary = {}
var stash: Dictionary = {}
var bag_list: VBoxContainer
var stash_list: VBoxContainer
var bag_title: Label
var stash_title: Label
var detail_label: Label

func _ready() -> void:
	_build_ui()
	visible = false
	refresh()

func set_context(data: Dictionary, stash_data: Dictionary) -> void:
	player_data = data.duplicate(true)
	stash = StashStorageServiceScript.normalize_stash(stash_data)
	refresh()

func refresh() -> void:
	if not is_instance_valid(bag_list) or not is_instance_valid(stash_list):
		return
	for child in bag_list.get_children():
		child.queue_free()
	for child in stash_list.get_children():
		child.queue_free()
	var inventory := InventoryDataServiceScript.normalize_inventory(player_data.get("inventory", {}))
	_update_titles(inventory)
	_build_item_buttons(bag_list, inventory, "Store", _on_deposit_pressed)
	_build_item_buttons(stash_list, stash, "Take", _on_withdraw_pressed)
	if is_instance_valid(detail_label) and detail_label.text == "":
		detail_label.text = "Select Store or Take to move a full stack or one equipment instance."

func deposit_item_for_test(item_id: String) -> void:
	_on_deposit_pressed(item_id)

func withdraw_item_for_test(item_id: String) -> void:
	_on_withdraw_pressed(item_id)

func get_visible_bag_item_ids_for_test() -> Array[String]:
	return _sorted_item_ids(InventoryDataServiceScript.normalize_inventory(player_data.get("inventory", {})))

func get_visible_stash_item_ids_for_test() -> Array[String]:
	return _sorted_item_ids(stash)

func _build_ui() -> void:
	name = "StashWindow"
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	size = Vector2(920, 560)
	position = Vector2(180, 80)

	var panel := PanelContainer.new()
	panel.name = "StashPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	DarkArpgUiThemeScript.style_panel(panel, true)
	add_child(panel)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 8)
	panel.add_child(root_box)

	var header := HBoxContainer.new()
	root_box.add_child(header)

	var title := Label.new()
	title.text = "Stash"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DarkArpgUiThemeScript.style_title(title, 24)
	header.add_child(title)

	var close_button := Button.new()
	close_button.name = "CloseStashButton"
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(36, 32)
	DarkArpgUiThemeScript.style_button(close_button)
	close_button.pressed.connect(func():
		visible = false
		close_requested.emit()
	)
	header.add_child(close_button)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root_box.add_child(body)

	var bag_panel := _make_column("Bag")
	body.add_child(bag_panel)
	bag_title = bag_panel.get_node("ColumnTitle") as Label
	bag_list = bag_panel.get_node("Scroll/List") as VBoxContainer

	var stash_panel := _make_column("Stash")
	body.add_child(stash_panel)
	stash_title = stash_panel.get_node("ColumnTitle") as Label
	stash_list = stash_panel.get_node("Scroll/List") as VBoxContainer

	detail_label = Label.new()
	detail_label.name = "StashDetail"
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.custom_minimum_size = Vector2(220, 0)
	detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	DarkArpgUiThemeScript.style_body_label(detail_label, 15)
	body.add_child(detail_label)

func _make_column(title_text: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(320, 0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.name = "ColumnTitle"
	title.text = title_text
	DarkArpgUiThemeScript.style_title(title, 17)
	column.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "List"
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)
	return column

func _update_titles(inventory: Dictionary) -> void:
	if is_instance_valid(bag_title):
		var bag_capacity: Dictionary = InventoryDataServiceScript.build_capacity_summary(inventory)
		bag_title.text = str(bag_capacity.get("summary_text", "Bag"))
	if is_instance_valid(stash_title):
		var stash_capacity: Dictionary = StashStorageServiceScript.build_capacity_summary(stash)
		stash_title.text = "Stash %d/%d" % [int(stash_capacity.get("used_slots", 0)), int(stash_capacity.get("capacity", 0))]

func _build_item_buttons(parent: VBoxContainer, container: Dictionary, action_label: String, callback: Callable) -> void:
	var ids := _sorted_item_ids(container)
	if ids.is_empty():
		var empty := Label.new()
		empty.text = "Empty"
		DarkArpgUiThemeScript.style_body_label(empty, 15, true)
		parent.add_child(empty)
		return
	for item_id in ids:
		var entry: Dictionary = Dictionary(container[item_id])
		var button := Button.new()
		button.text = "%s  %s" % [action_label, _format_item(entry)]
		button.custom_minimum_size = Vector2(300, 34)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		DarkArpgUiThemeScript.style_button(button)
		button.pressed.connect(func(): callback.call(item_id))
		parent.add_child(button)

func _on_deposit_pressed(item_id: String) -> void:
	var result := StashStorageServiceScript.deposit_item(player_data, stash, item_id)
	_apply_transfer_result(result)

func _on_withdraw_pressed(item_id: String) -> void:
	var result := StashStorageServiceScript.withdraw_item(player_data, stash, item_id)
	_apply_transfer_result(result)

func _apply_transfer_result(result: Dictionary) -> void:
	if not bool(result.get("ok", false)):
		if is_instance_valid(detail_label):
			detail_label.text = "Cannot move item: %s" % str(result.get("reason", "unknown"))
		return
	player_data = Dictionary(result.get("player_data", player_data))
	stash = StashStorageServiceScript.normalize_stash(result.get("stash", stash))
	player_data_changed.emit(player_data.duplicate(true))
	stash_changed.emit(stash.duplicate(true))
	if is_instance_valid(detail_label):
		detail_label.text = "Moved %s." % str(result.get("item_id", "item"))
	refresh()

func _format_item(entry: Dictionary) -> String:
	var name := str(entry.get("name", entry.get("id", "Item")))
	var amount := int(entry.get("amount", 1))
	if str(entry.get("type", "")) == "equipment":
		return name
	return "%s x%d" % [name, amount]

func _sorted_item_ids(container: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for item_id in container.keys():
		ids.append(str(item_id))
	ids.sort()
	return ids
