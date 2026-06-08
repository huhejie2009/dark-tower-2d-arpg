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
			scene.call("_apply_floor_template_for_test", 3)
			await process_frame
			var enemy_types := _collect_enemy_types()
			_expect(enemy_types.has("shadow_archer"), "floor 3 should spawn shadow archer pressure")
			scene.call("_apply_floor_template_for_test", 4)
			await process_frame
			enemy_types = _collect_enemy_types()
			_expect(enemy_types.has("tower_guardian"), "floor 4 should spawn tower guardian")
		scene.queue_free()
		await process_frame
	_finish()

func _collect_enemy_types() -> Array[String]:
	var result: Array[String] = []
	for enemy in get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			result.append(str(enemy.get("enemy_type")))
	return result

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_GAME2D_FLOOR_TEMPLATE_SPAWN_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
