extends SceneTree

const GameScene := preload("res://scenes/Game2D.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := GameScene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var player := scene.get("player") as Node
	for enemy in get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(9999, player)
	await process_frame
	_expect(bool(scene.get("portal_available")), "floor clear should open portal")
	_expect(scene.get_node_or_null("ArenaRoot/NextFloorPortal") != null, "portal node should exist")
	scene.call("_enter_next_floor")
	await process_frame
	_expect(not bool(scene.get("portal_available")), "entering next floor should consume portal")
	_expect(int(scene.get("current_floor")) >= 2, "floor should advance")
	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_FLOOR_CLEAR_PORTAL_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
