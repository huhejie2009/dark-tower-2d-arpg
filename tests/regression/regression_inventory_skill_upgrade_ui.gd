extends SceneTree

const WindowScript := preload("res://scripts/ui/InventoryEquipmentWindow.gd")
const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")

var failures: Array[String] = []
var changed_data: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var window := WindowScript.new()
	root.add_child(window)
	await process_frame
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Skill UI", "warrior")
	player["skill_points"] = 1
	player["attack_damage"] = 30
	player["unlocked_skill_nodes"] = {}
	window.player_data_changed.connect(func(data: Dictionary): changed_data = data.duplicate(true))
	window.set_player_data(player)
	await process_frame
	_expect(window.find_child("SkillPointSummary", true, false) != null, "inventory window should show skill point summary")
	_expect(window.find_child("UpgradeBasicAttackButton", true, false) != null, "inventory window should expose basic attack upgrade button")
	var summary := window.find_child("SkillPointSummary", true, false) as Label
	if summary != null:
		_expect(str(summary.text).contains("SP 1"), "skill summary should show available skill points")
	var button := window.find_child("UpgradeBasicAttackButton", true, false) as Button
	if button != null:
		button.pressed.emit()
		await process_frame
		_expect(not changed_data.is_empty(), "pressing upgrade should emit player data change")
		_expect(int(changed_data.get("skill_points", -1)) == 0, "upgrade button should consume a skill point")
		_expect(int(changed_data.get("attack_damage", 0)) == 33, "upgrade button should increase attack damage")
	window.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_INVENTORY_SKILL_UPGRADE_UI_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
