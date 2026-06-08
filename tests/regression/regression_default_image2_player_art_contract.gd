extends SceneTree

const Game2DScene := preload("res://scenes/Game2D.tscn")

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
		_expect(str(contract.get("player_asset_pipeline", "")) == "IMAGE2", "default player art should use IMAGE2 pipeline")
		_expect(str(contract.get("player_sprite_path", "")).ends_with("player_warrior_sheet_v3.png"), "default player art should reference production player spritesheet")
		_expect(bool(contract.get("player_sprite_loaded", false)), "default player sprite should load")
		_expect(bool(contract.get("player_procedural_hidden", false)), "default player procedural body should be hidden after IMAGE2 art loads")

	var player := scene.find_child("Player2D", true, false)
	_expect(player != null, "player should exist")
	if player != null:
		var actor_sprite := player.find_child("ActorSprite", true, false) as Sprite2D
		_expect(actor_sprite != null, "player should have ActorSprite")
		if actor_sprite != null:
			_expect(actor_sprite.visible, "player ActorSprite should be visible")
			_expect(actor_sprite.texture != null, "player ActorSprite should have generated texture")
			_expect(actor_sprite.region_rect.size == Vector2(160, 160), "player ActorSprite should use 160x160 animation frames")
		var body := player.find_child("PlayerBody", true, false) as CanvasItem
		_expect(body != null and not body.visible, "procedural player body should be hidden")
		if player.has_method("get_visual_asset_manifest_for_test"):
			var manifest: Dictionary = player.call("get_visual_asset_manifest_for_test")
			_expect(str(manifest.get("pose_variation_version", "")) == "production_dark_armor_v3", "default player should use production dark armor manifest")
			var animations: Dictionary = Dictionary(manifest.get("animations", {}))
			_expect(animations.has("idle") and animations.has("run") and animations.has("attack") and animations.has("death"), "default player should expose idle/run/attack/death animation segments")

	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_DEFAULT_IMAGE2_PLAYER_ART_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
