extends SceneTree

const Game2DScene := preload("res://scenes/Game2D.tscn")
const FloorRulesScript := preload("res://scripts/rules/FloorRules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := Game2DScene.instantiate()
	root.add_child(scene)
	await process_frame

	_expect(scene.has_method("_get_default_actor_art_contract_for_test"), "Game2D should expose default actor art contract")
	if scene.has_method("_get_default_actor_art_contract_for_test"):
		var contract: Dictionary = scene.call("_get_default_actor_art_contract_for_test")
		_expect(str(contract.get("actor_art_family", "")) == "dark_high_res_pixel_actor", "player art contract should declare the pixel actor family")
		_expect(str(contract.get("actor_environment_pairing", "")) == "painterly_brutalist_tower", "player art should declare painterly tower environment pairing")
		_expect(str(contract.get("actor_texture_filter", "")) == "nearest", "player art should request nearest filtering")
		_expect(str(contract.get("actor_directional_target", "")) == "4dir", "player art should target 4dir production sheets")

	var player := scene.find_child("Player2D", true, false)
	_expect(player != null, "player should exist")
	if player != null and player.has_method("get_actor_presentation_state_for_test"):
		var player_state: Dictionary = player.call("get_actor_presentation_state_for_test")
		_expect(int(player_state.get("texture_filter", -1)) == CanvasItem.TEXTURE_FILTER_NEAREST, "player sprite should use nearest filtering for pixel actor trial")

	for enemy_type in ["rot_melee", "shadow_archer"]:
		var data: Dictionary = FloorRulesScript.get_enemy_type_data(enemy_type, 1)
		var manifest: Dictionary = Dictionary(data.get("visual_asset_manifest", {}))
		_assert_pixel_manifest(manifest, enemy_type)

	scene.queue_free()
	await process_frame
	_finish()

func _assert_pixel_manifest(manifest: Dictionary, label: String) -> void:
	_expect(str(manifest.get("art_family", "")) == "dark_high_res_pixel_actor", "%s should declare the pixel actor family" % label)
	_expect(str(manifest.get("environment_pairing", "")) == "painterly_brutalist_tower", "%s should pair with painterly brutalist tower environments" % label)
	_expect(str(manifest.get("texture_filter", "")) == "nearest", "%s should request nearest filtering" % label)
	_expect(str(manifest.get("directional_target", "")) == "4dir", "%s should target 4dir production sheets" % label)
	_expect(bool(manifest.get("separate_combat_vfx", false)), "%s should keep combat VFX separate from actor animation" % label)
	var contact_shadow: Dictionary = Dictionary(manifest.get("contact_shadow", {}))
	_expect(bool(contact_shadow.get("required", false)), "%s should require grounded contact shadow" % label)

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_PIXEL_ACTOR_ART_TRIAL_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
