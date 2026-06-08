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
