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
		_expect(scene.has_method("_apply_floor_template_for_test"), "Game2D should expose floor template test hook")
		if scene.has_method("_apply_floor_template_for_test"):
			await _check_floor_enemy_replacements(scene, 1, ["rot_melee"])
			await _check_floor_enemy_replacements(scene, 2, ["rot_melee"])
			await _check_floor_enemy_replacements(scene, 3, ["rot_melee", "shadow_archer"])
			await _check_floor_enemy_replacements(scene, 4, ["rot_melee", "shadow_archer", "tower_guardian"])
			await _check_floor_enemy_replacements(scene, 5, ["rot_melee"])
		scene.queue_free()
		await process_frame
	_finish()

func _check_floor_enemy_replacements(scene: Node, floor: int, expected_types: Array[String]) -> void:
	scene.call("_apply_floor_template_for_test", floor)
	await process_frame
	var found_types: Dictionary = {}
	for enemy in get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var enemy_type := str(enemy.get("enemy_type"))
		if not expected_types.has(enemy_type):
			continue
		found_types[enemy_type] = true
		var manifest: Dictionary = Dictionary(enemy.call("get_visual_asset_manifest_for_test"))
		_expect(not manifest.is_empty(), "floor %d %s should keep visual manifest after spawn" % [floor, enemy_type])
		_expect(str(manifest.get("asset_pipeline", "")) == "image2", "floor %d %s should use IMAGE2 pipeline" % [floor, enemy_type])
		var actor_sprite := enemy.find_child("ActorSprite", true, false) as Sprite2D
		_expect(actor_sprite != null and actor_sprite.texture != null, "floor %d %s should use spritesheet texture" % [floor, enemy_type])
		var body := enemy.find_child("EnemyBody", true, false) as CanvasItem
		_expect(body != null and not body.visible, "floor %d %s procedural body should be hidden" % [floor, enemy_type])
	for expected_type in expected_types:
		_expect(found_types.has(expected_type), "floor %d should spawn checked enemy type %s" % [floor, expected_type])

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_GAME2D_IMAGE2_ENEMY_REPLACEMENT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
