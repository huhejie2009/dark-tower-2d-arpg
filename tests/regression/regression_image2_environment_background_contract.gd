extends SceneTree

const Game2DScene := preload("res://scenes/Game2D.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := Game2DScene.instantiate()
	root.add_child(scene)
	await process_frame

	_expect(scene.has_method("_get_environment_asset_contract_for_test"), "Game2D should expose environment asset contract")
	if scene.has_method("_get_environment_asset_contract_for_test"):
		var contract: Dictionary = scene.call("_get_environment_asset_contract_for_test")
		_expect(str(contract.get("asset_pipeline", "")) == "IMAGE2", "environment background should use IMAGE2 asset pipeline")
		_expect(str(contract.get("background_path", "")).begins_with("res://assets/generated/environments/"), "environment background should live under generated environment assets")
		_expect(str(contract.get("background_path", "")).contains("tower_interior_brutalist_room"), "environment background should be the cold brutalist tower interior asset")
		_expect(str(contract.get("world_art_anchor", "")) == "cold_megastructure_dark_core", "environment should follow the approved cold megastructure dark-core concept")
		_expect(str(contract.get("forbidden_style", "")) == "mhxy_ornate_palace", "environment contract should explicitly reject the old ornate palace direction")
		_expect(bool(contract.get("background_loaded", false)), "environment background texture should load")
		_expect(bool(contract.get("procedural_visuals_muted", false)), "procedural geometry should be visually muted when IMAGE2 background is loaded")

	var bg := scene.find_child("IMAGE2EnvironmentBackground", true, false) as Sprite2D
	_expect(bg != null, "Game2D should create IMAGE2 environment background sprite")
	if bg != null:
		_expect(bg.texture != null, "IMAGE2 environment background sprite should have a texture")
		_expect(bg.z_index < -50, "IMAGE2 environment background should render behind actors and effects")
		var texture_size := bg.texture.get_size() if bg.texture != null else Vector2.ZERO
		_expect(texture_size.x >= 1200.0 and texture_size.y >= 700.0, "tower interior background should have enough resolution for the combat viewport")

	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_IMAGE2_ENVIRONMENT_BACKGROUND_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
