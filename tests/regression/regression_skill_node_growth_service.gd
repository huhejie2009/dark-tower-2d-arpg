extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const SkillNodeGrowthServiceScript := preload("res://scripts/data/SkillNodeGrowthService.gd")
const SkillUpgradePreviewServiceScript := preload("res://scripts/data/SkillUpgradePreviewService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "Skill Nodes", "warrior")
	player["skill_points"] = 3
	player["attack_damage"] = 30
	player["max_health"] = 120
	player["health"] = 80
	player["critical_chance"] = 0
	player["unlocked_skill_nodes"] = {}

	var nodes: Array = SkillNodeGrowthServiceScript.list_nodes()
	_expect(nodes.size() >= 3, "skill node service should expose at least three nodes")
	var node_ids: Array[String] = []
	for node in nodes:
		var entry: Dictionary = Dictionary(node)
		node_ids.append(str(entry.get("node_id", "")))
		_expect(str(entry.get("title", "")) != "", "each skill node should expose title")
		_expect(str(entry.get("stat_id", "")) != "", "each skill node should expose stat id")
		_expect(int(entry.get("max_level", 0)) > 0, "each skill node should expose max level")
		_expect(int(entry.get("skill_point_cost", 0)) == 1, "first pass skill nodes should cost one point")
	_expect(node_ids.has("basic_attack_training"), "nodes should include basic attack training")
	_expect(node_ids.has("vitality_training"), "nodes should include vitality training")
	_expect(node_ids.has("precision_training"), "nodes should include precision training")

	var vitality_preview: Dictionary = SkillNodeGrowthServiceScript.build_preview(player, "vitality_training")
	_expect(bool(vitality_preview.get("can_upgrade", false)), "vitality preview should be upgradeable")
	_expect(str(vitality_preview.get("stat_id", "")) == "max_health", "vitality should affect max health")
	_expect(int(vitality_preview.get("stat_gain", 0)) == 12, "vitality should expose health gain")
	_expect(str(vitality_preview.get("summary_text", "")).contains("Health +12"), "vitality summary should describe gain")

	var vitality_result: Dictionary = SkillNodeGrowthServiceScript.upgrade_node(player, "vitality_training")
	_expect(bool(vitality_result.get("ok", false)), "vitality upgrade should succeed")
	var after_vitality: Dictionary = Dictionary(vitality_result.get("player_data", player))
	_expect(int(after_vitality.get("skill_points", -1)) == 2, "vitality upgrade should consume one skill point")
	_expect(int(after_vitality.get("max_health", 0)) == 132, "vitality upgrade should increase max health")
	_expect(int(after_vitality.get("health", 0)) == 92, "vitality upgrade should also add current health")
	_expect(int(Dictionary(after_vitality.get("unlocked_skill_nodes", {})).get("vitality_training", 0)) == 1, "vitality node level should increase")

	var precision_result: Dictionary = SkillNodeGrowthServiceScript.upgrade_node(after_vitality, "precision_training")
	_expect(bool(precision_result.get("ok", false)), "precision upgrade should succeed")
	var after_precision: Dictionary = Dictionary(precision_result.get("player_data", after_vitality))
	_expect(int(after_precision.get("critical_chance", 0)) == 2, "precision upgrade should increase critical chance")

	var all_previews: Array = SkillUpgradePreviewServiceScript.build_all_previews(after_precision)
	_expect(all_previews.size() >= 3, "preview service should expose all skill node previews")
	var found_precision_preview := false
	for preview in all_previews:
		if str(Dictionary(preview).get("node_id", "")) == "precision_training":
			found_precision_preview = true
	_expect(found_precision_preview, "all previews should include precision training")

	var legacy_result: Dictionary = PlayerDataServiceScript.upgrade_basic_attack(after_precision)
	_expect(bool(legacy_result.get("ok", false)), "legacy basic attack upgrade should still work")
	_expect(int(Dictionary(Dictionary(legacy_result.get("player_data", after_precision)).get("unlocked_skill_nodes", {})).get("basic_attack_training", 0)) == 1, "legacy wrapper should upgrade basic attack node")

	var blocked := after_precision.duplicate(true)
	blocked["skill_points"] = 0
	var blocked_result: Dictionary = SkillNodeGrowthServiceScript.upgrade_node(blocked, "vitality_training")
	_expect(not bool(blocked_result.get("ok", true)), "node upgrade should fail without skill points")
	_expect(str(blocked_result.get("reason", "")) == "no_skill_points", "blocked upgrade should expose reason")

	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_SKILL_NODE_GROWTH_SERVICE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
