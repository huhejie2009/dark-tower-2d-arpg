extends SceneTree

const WindowScript := preload("res://scripts/ui/InventoryEquipmentWindow.gd")
const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Skill Readability", "warrior")
	player["skill_points"] = 1
	player["attack_damage"] = 30
	player["unlocked_skill_nodes"] = {}

	var window := WindowScript.new()
	root.add_child(window)
	await process_frame
	window.set_player_data(player)
	await process_frame

	_expect(window.has_method("get_basic_attack_upgrade_preview_for_test"), "inventory should expose skill upgrade preview")
	if window.has_method("get_basic_attack_upgrade_preview_for_test"):
		var preview: Dictionary = Dictionary(window.call("get_basic_attack_upgrade_preview_for_test"))
		_expect(bool(preview.get("can_upgrade", false)), "preview should mark upgrade as available")
		_expect(str(preview.get("node_id", "")) == "basic_attack_training", "preview should expose node id")
		_expect(int(preview.get("current_level", -1)) == 0, "preview should expose current level")
		_expect(int(preview.get("next_level", -1)) == 1, "preview should expose next level")
		_expect(int(preview.get("max_level", 0)) == 5, "preview should expose max level")
		_expect(int(preview.get("skill_point_cost", 0)) == 1, "preview should expose skill point cost")
		_expect(int(preview.get("damage_gain", 0)) == 3, "preview should expose damage gain")
		_expect(str(preview.get("reason", "")) == "ready", "available preview should use ready reason")
		_expect(str(preview.get("summary_text", "")).contains("Damage +3"), "preview summary should describe gain")
		_expect(str(preview.get("status_text", "")).contains("Ready"), "preview status should be readable")

	var summary := window.find_child("SkillPointSummary", true, false) as Label
	if summary != null:
		var summary_text := str(summary.text)
		_expect(summary_text.contains("SP 1"), "summary should show skill points")
		_expect(summary_text.contains("Next +3 Damage"), "summary should show next damage gain")
		_expect(summary_text.contains("Cost 1 SP"), "summary should show skill point cost")

	var button := window.find_child("UpgradeBasicAttackButton", true, false) as Button
	if button != null:
		_expect(str(button.tooltip_text).contains("Damage +3"), "button tooltip should describe upgrade gain")
		_expect(str(button.tooltip_text).contains("Cost 1 SP"), "button tooltip should describe cost")

	player["skill_points"] = 0
	window.set_player_data(player)
	await process_frame
	if window.has_method("get_basic_attack_upgrade_preview_for_test"):
		var blocked: Dictionary = Dictionary(window.call("get_basic_attack_upgrade_preview_for_test"))
		_expect(not bool(blocked.get("can_upgrade", true)), "preview should block upgrade without skill points")
		_expect(str(blocked.get("reason", "")) == "no_skill_points", "preview should expose no skill point reason")
		_expect(str(blocked.get("status_text", "")).contains("Need 1 SP"), "blocked preview should explain missing SP")
	if button != null:
		_expect(button.disabled, "button should be disabled without skill points")

	window.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_SKILL_UPGRADE_READABILITY_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
