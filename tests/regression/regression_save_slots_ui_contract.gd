extends SceneTree

const SaveSchemaScript := preload("res://scripts/save/SaveSchema.gd")
const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var save := SaveSchemaScript.default_save()
	var manager := SaveManagerScript.new()
	if not manager.has_method("set_active_slot_in_data"):
		_expect(false, "SaveManager should expose set_active_slot_in_data")
	else:
		_expect(Dictionary(manager.call("set_active_slot_in_data", save, "slot_2")).get("active_slot_id", "") == "slot_2", "slot_2 should become active in save data")
		_expect(Dictionary(manager.call("set_active_slot_in_data", save, "bad_slot")).get("active_slot_id", "") == "slot_1", "bad slot should fall back to slot_1")

	var packed := load("res://scenes/CharacterSelect.tscn")
	_expect(packed is PackedScene, "CharacterSelect should load")
	if packed is PackedScene:
		var scene: Node = packed.instantiate()
		root.add_child(scene)
		await process_frame
		for slot_id in SaveSchemaScript.SLOT_IDS:
			_expect(scene.find_child("SlotButton%s" % slot_id.capitalize(), true, false) != null, "slot button should exist for %s" % slot_id)
		_expect(scene.find_child("CreateCharacterButton", true, false) != null, "create character button should exist")
		var selected_slot_label := scene.find_child("SelectedSlotSummary", true, false) as Label
		var selected_class_label := scene.find_child("SelectedClassSummary", true, false) as Label
		_expect(selected_slot_label != null, "character select should show selected slot summary")
		_expect(selected_class_label != null, "character select should show selected class summary")
		if selected_slot_label != null:
			_expect(str(selected_slot_label.text).contains("slot_1"), "selected slot summary should show initial slot")
		if selected_class_label != null:
			_expect(str(selected_class_label.text).contains("warrior"), "selected class summary should show initial class")
		var slot_1 := scene.find_child("SlotButtonSlot_1", true, false) as Button
		var warrior := scene.find_child("ClassButtonWarrior", true, false) as Button
		if slot_1 != null:
			_expect(slot_1.toggle_mode, "slot buttons should expose a selected state")
			_expect(slot_1.button_pressed, "initial selected slot button should be pressed")
		if warrior != null:
			_expect(warrior.toggle_mode, "class buttons should expose a selected state")
			_expect(warrior.button_pressed, "initial selected class button should be pressed")
		var slot_3 := scene.find_child("SlotButtonSlot_3", true, false) as Button
		if slot_3 != null:
			slot_3.pressed.emit()
			await process_frame
			if selected_slot_label != null:
				_expect(str(selected_slot_label.text).contains("slot_3"), "selected slot summary should update after empty slot click")
			_expect(slot_3.button_pressed, "clicked empty slot should become pressed")
			if slot_1 != null:
				_expect(not slot_1.button_pressed, "previous slot button should unpress after slot change")
		var mage := scene.find_child("ClassButtonMage", true, false) as Button
		if mage != null:
			mage.pressed.emit()
			await process_frame
			if selected_class_label != null:
				_expect(str(selected_class_label.text).contains("mage"), "selected class summary should update after class click")
			_expect(mage.button_pressed, "clicked class should become pressed")
			if warrior != null:
				_expect(not warrior.button_pressed, "previous class button should unpress after class change")
		scene.queue_free()
		await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_SAVE_SLOTS_UI_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
