extends RefCounted
class_name SkillUpgradePreviewService

const PlayerDataServiceScript := preload("res://scripts/data/PlayerDataService.gd")
const SkillNodeGrowthServiceScript := preload("res://scripts/data/SkillNodeGrowthService.gd")

static func build_basic_attack_preview(player_data: Dictionary) -> Dictionary:
	return SkillNodeGrowthServiceScript.build_preview(player_data, PlayerDataServiceScript.BASIC_ATTACK_TRAINING_NODE)

static func build_all_previews(player_data: Dictionary) -> Array:
	return SkillNodeGrowthServiceScript.build_all_previews(player_data)
