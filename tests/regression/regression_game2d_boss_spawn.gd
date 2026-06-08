extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/Game2D.tscn")
	_expect(packed is PackedScene, "Game2D should load")
	if packed is PackedScene:
		var scene: Node = packed.instantiate()
		root.add_child(scene)
		await process_frame
		scene.call("_apply_floor_template_for_test", 5)
		await process_frame
		var found_boss := false
		for enemy in get_nodes_in_group("enemies"):
			if str(enemy.get("enemy_type")) == "tower_gatekeeper":
				found_boss = true
				_expect(enemy.get("is_boss") == true, "spawned gatekeeper should be boss")
				var manifest: Dictionary = Dictionary(enemy.call("get_visual_asset_manifest_for_test"))
				_expect(str(manifest.get("pose_variation_version", "")) == "production_dark_armor_v3", "spawned gatekeeper should use production dark armor manifest")
				_expect(str(manifest.get("sprite_sheet_path", "")).ends_with("boss_tower_gatekeeper_sheet_v3.png"), "spawned gatekeeper should reference production boss spritesheet")
				_expect(manifest.get("frame_size", Vector2i.ZERO) == Vector2i(192, 192), "spawned gatekeeper should use 192x192 boss frames")
				var actor_sprite := enemy.find_child("ActorSprite", true, false) as Sprite2D
				_expect(actor_sprite != null and actor_sprite.texture != null and actor_sprite.visible, "spawned gatekeeper should load visible boss spritesheet texture")
				var body := enemy.find_child("EnemyBody", true, false) as CanvasItem
				_expect(body != null and not body.visible, "spawned gatekeeper procedural body should be hidden")
		_expect(found_boss, "floor 5 should spawn tower gatekeeper")
		scene.queue_free()
		await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_GAME2D_BOSS_SPAWN_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
