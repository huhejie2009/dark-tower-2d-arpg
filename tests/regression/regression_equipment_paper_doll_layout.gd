extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const InventoryEquipmentWindowScript := preload("res://scripts/ui/InventoryEquipmentWindow.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Test", "warrior")
	var window := InventoryEquipmentWindowScript.new()
	root.add_child(window)
	window.set_player_data(player)
	await process_frame

	_expect(window.find_child("EquipmentPaperDollPanel", true, false) != null, "equipment window should expose paper doll panel")
	_expect(window.find_child("PaperDollClassLabel", true, false) != null, "paper doll should show class label")
	_expect(window.find_child("PaperDollScoreLabel", true, false) != null, "paper doll should show total equipment score")
	_expect(window.find_child("PaperDollAnchor", true, false) != null, "paper doll should expose visual anchor for future character art")
	_expect(window.find_child("EquipmentSlotWeapon", true, false) != null, "weapon slot button should still exist")
	_expect(window.find_child("EquipmentSlotArmor", true, false) != null, "armor slot button should still exist")
	_expect(window.has_method("get_equipment_slot_summary_for_test"), "window should expose equipment slot summary")

	if window.has_method("get_equipment_slot_summary_for_test"):
		var weapon_summary: Dictionary = Dictionary(window.call("get_equipment_slot_summary_for_test", "weapon"))
		_expect(str(weapon_summary.get("slot", "")) == "weapon", "slot summary should include slot id")
		_expect(str(weapon_summary.get("item_id", "")) != "", "weapon summary should include equipped item id")
		_expect(not bool(weapon_summary.get("empty", true)), "starter weapon slot should not be empty")
		_expect(int(weapon_summary.get("score", 0)) > 0, "equipped weapon summary should include score")
		var armor_summary: Dictionary = Dictionary(window.call("get_equipment_slot_summary_for_test", "armor"))
		_expect(bool(armor_summary.get("empty", false)), "starter armor slot should be empty")

	window.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_EQUIPMENT_PAPER_DOLL_LAYOUT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
