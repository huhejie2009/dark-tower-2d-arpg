extends SceneTree

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const SkillNodeGrowthServiceScript := preload("res://scripts/data/SkillNodeGrowthService.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PlayerDataServiceScript.build_starter_player("slot_1", "CoC Nodes", "ranger")
	player["skill_points"] = 6
	var precision: Dictionary = SkillNodeGrowthServiceScript.upgrade_node(player, "ranger_coc_precision")
	_expect(bool(precision.get("ok", false)), "precision node should upgrade")
	player = Dictionary(precision.get("player_data", player))
	var ice: Dictionary = SkillNodeGrowthServiceScript.upgrade_node(player, "ranger_ice_mastery")
	_expect(bool(ice.get("ok", false)), "ice mastery node should upgrade")
	player = Dictionary(ice.get("player_data", player))
	var split: Dictionary = SkillNodeGrowthServiceScript.upgrade_node(player, "ranger_projectile_split")
	_expect(bool(split.get("ok", false)), "split node should upgrade")
	player = Dictionary(split.get("player_data", player))

	_expect(int(player.get("critical_chance", 0)) >= 11, "precision should increase crit from ranger starter crit")
	_expect(int(player.get("cold_damage", 0)) == 5, "ice mastery should increase cold damage")
	_expect(int(player.get("ice_lance_split", 0)) == 1, "split node should increase ice lance split")
	_expect(int(player.get("skill_points", -1)) == 2, "upgrades should spend four skill points")

	var reset: Dictionary = SkillNodeGrowthServiceScript.reset_skill_nodes(player)
	_expect(bool(reset.get("ok", false)), "reset should succeed")
	var reset_player: Dictionary = Dictionary(reset.get("player_data", {}))
	_expect(int(reset.get("refunded_skill_points", 0)) == 4, "reset should refund spent points")
	_expect(Dictionary(reset_player.get("unlocked_skill_nodes", {})).is_empty(), "reset should clear node levels")
	_expect(int(reset_player.get("cold_damage", -1)) == 0, "reset should remove cold damage")
	_expect(int(reset_player.get("ice_lance_split", -1)) == 0, "reset should remove split mechanic")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_RANGER_COC_SKILL_NODES_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
