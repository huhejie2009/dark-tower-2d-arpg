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
	var player := scene.get("player") as CharacterBody2D
	_expect(is_instance_valid(player), "Game2D should create Player2D")
	if is_instance_valid(player):
		player.set("max_health", 9999)
		player.set("health", 9999)
		var before := player.global_position
		Input.action_press("move_right")
		for _i in range(12):
			await physics_frame
		Input.action_release("move_right")
		_expect(player.global_position.x > before.x + 1.0, "move_right should move player")
		var enemy := _first_enemy()
		_expect(is_instance_valid(enemy), "Game2D should spawn enemy")
		if is_instance_valid(enemy):
			(enemy as Node2D).global_position = player.global_position + Vector2(70, 0)
			player.rotation = 0.0
			var hp_before := int(enemy.get("health"))
			scene.call("_input", _mouse_click())
			_expect(int(enemy.get("health")) < hp_before, "left mouse should attack an enemy")
	scene.queue_free()
	await process_frame
	_finish()

func _mouse_click() -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	return event

func _first_enemy() -> Node:
	var enemies := get_nodes_in_group("enemies")
	return enemies[0] if enemies.size() > 0 else null

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_GAME2D_INPUT_CONTRACT_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
