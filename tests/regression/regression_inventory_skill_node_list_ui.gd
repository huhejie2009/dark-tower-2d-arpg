extends SceneTree

const WindowScript := preload("res://scripts/ui/InventoryEquipmentWindow.gd")
const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")

var failures: Array[String] = []
var changed_data: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Skill Node UI", "warrior")
	player["skill_points"] = 2
	player["attack_damage"] = 30
	player["max_health"] = 120
	player["health"] = 80
	player["unlocked_skill_nodes"] = {}

	var window := WindowScript.new()
	root.add_child(window)
	window.player_data_changed.connect(func(data: Dictionary): changed_data = data.duplicate(true))
	await process_frame
	window.set_player_data(player)
	await process_frame

	_expect(window.find_child("SkillNodeList", true, false) != null, "inventory should expose compact skill node list")
	_expect(window.find_child("SkillNodeBasicAttackTraining", true, false) != null, "skill list should include basic attack node")
	_expect(window.find_child("SkillNodeVitalityTraining", true, false) != null, "skill list should include vitality node")
	_expect(window.find_child("SkillNodePrecisionTraining", true, false) != null, "skill list should include precision node")
	_expect(window.find_child("UpgradeSelectedSkillButton", true, false) != null, "inventory should expose generic selected skill upgrade button")
	_expect(window.has_method("select_skill_node"), "window should expose select_skill_node")
	_expect(window.has_method("upgrade_selected_skill_node"), "window should expose upgrade_selected_skill_node")
	_expect(window.has_method("get_selected_skill_node_id"), "window should expose selected skill node id")
	_expect(window.has_method("get_skill_node_previews_for_test"), "window should expose all skill previews for tests")

	if window.has_method("get_skill_node_previews_for_test"):
		var previews: Array = Array(window.call("get_skill_node_previews_for_test"))
		_expect(previews.size() >= 3, "skill preview list should include all starter nodes")

	if window.has_method("select_skill_node"):
		window.call("select_skill_node", "vitality_training")
		await process_frame
		_expect(str(window.call("get_selected_skill_node_id")) == "vitality_training", "selecting vitality should update selected skill node id")
		var summary := window.find_child("SkillPointSummary", true, false) as Label
		if summary != null:
			var text := str(summary.text)
			_expect(text.contains("Vitality Training"), "summary should show selected skill title")
			_expect(text.contains("Health +12"), "summary should show selected skill gain")

	var upgrade_button := window.find_child("UpgradeSelectedSkillButton", true, false) as Button
	if upgrade_button != null:
		_expect(not upgrade_button.disabled, "selected upgrade button should be enabled with available skill points")
		upgrade_button.pressed.emit()
		await process_frame
		_expect(not changed_data.is_empty(), "upgrading selected node should emit player data")
		_expect(int(changed_data.get("skill_points", -1)) == 1, "selected node upgrade should consume one skill point")
		_expect(int(changed_data.get("max_health", 0)) == 132, "vitality upgrade should increase max health")
		_expect(int(Dictionary(changed_data.get("unlocked_skill_nodes", {})).get("vitality_training", 0)) == 1, "vitality node level should increase")

	window.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_INVENTORY_SKILL_NODE_LIST_UI_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
