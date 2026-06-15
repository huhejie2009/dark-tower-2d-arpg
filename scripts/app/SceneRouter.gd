extends RefCounted
class_name SceneRouter

const GameConstantsScript := preload("res://scripts/app/GameConstants.gd")

static func go_to_main_menu(tree: SceneTree) -> void:
	tree.change_scene_to_file(GameConstantsScript.MAIN_MENU_SCENE)

static func go_to_character_select(tree: SceneTree) -> void:
	tree.change_scene_to_file(GameConstantsScript.CHARACTER_SELECT_SCENE)

static func go_to_town(tree: SceneTree) -> void:
	tree.change_scene_to_file(GameConstantsScript.TOWN_SCENE)

static func go_to_game(tree: SceneTree) -> void:
	tree.change_scene_to_file(GameConstantsScript.ACTIVE_GAME_SCENE)

static func get_active_game_scene_for_test() -> String:
	return GameConstantsScript.ACTIVE_GAME_SCENE
