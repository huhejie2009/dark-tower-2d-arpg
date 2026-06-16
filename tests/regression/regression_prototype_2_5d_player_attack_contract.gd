extends SceneTree

const PrototypeScene := preload("res://scenes/prototypes/Prototype2_5DCombatRoom.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := PrototypeScene.instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame

	_expect(scene.has_method("_input"), "prototype should handle left mouse input")
	_expect(scene.has_method("build_player_attack_snapshot_for_test"), "prototype should expose player attack snapshot")
	_expect(scene.has_method("set_player_attack_direction_for_test"), "prototype should expose deterministic attack direction")
	_expect(scene.has_method("set_player_position_for_test"), "prototype should expose deterministic player positioning")
	if not scene.has_method("build_player_attack_snapshot_for_test") or not scene.has_method("set_player_attack_direction_for_test") or not scene.has_method("set_player_position_for_test"):
		scene.queue_free()
		await process_frame
		_finish()
		return

	var initial_enemy_loop: Dictionary = scene.call("build_enemy_loop_snapshot_for_test")
	var enemy_states: Array = Array(initial_enemy_loop.get("enemy_states", []))
	_expect(enemy_states.size() == 2, "prototype should expose two enemies for attack test")
	if enemy_states.size() == 0:
		scene.queue_free()
		await process_frame
		_finish()
		return

	var first_enemy_position: Vector3 = Dictionary(enemy_states[0]).get("position", Vector3.ZERO)
	scene.call("set_player_position_for_test", first_enemy_position + Vector3(-0.75, 0.0, 0.0))
	scene.call("set_player_attack_direction_for_test", Vector2.RIGHT)
	await physics_frame

	var before_attack: Dictionary = scene.call("build_player_attack_snapshot_for_test")
	_expect(bool(before_attack.get("attack_ready", false)), "player attack should start ready")
	_expect(float(before_attack.get("attack_range", 0.0)) >= 1.0, "player attack should have a practical melee range")
	_expect(int(before_attack.get("total_attack_count", -1)) == 0, "attack count should start at zero")

	scene.call("_input", _mouse_click())
	await physics_frame

	var after_attack: Dictionary = scene.call("build_player_attack_snapshot_for_test")
	var after_enemy_loop: Dictionary = scene.call("build_enemy_loop_snapshot_for_test")
	_expect(int(after_attack.get("total_attack_count", 0)) == 1, "left mouse should trigger one player attack")
	_expect(int(after_attack.get("last_hit_count", 0)) == 1, "player attack should hit one enemy in front")
	_expect(str(after_attack.get("attack_phase", "")) != "ready", "accepted attack should enter a visible attack phase")
	_expect(not bool(after_attack.get("attack_ready", true)), "attack should start cooldown")
	_expect(int(after_enemy_loop.get("living_enemy_count", 0)) == 1, "hit enemy should be defeated by prototype attack")
	_expect(not bool(after_enemy_loop.get("exit_unlocked", true)), "exit should remain locked while one enemy remains")

	scene.call("set_player_attack_direction_for_test", Vector2.RIGHT)
	scene.call("set_player_position_for_test", first_enemy_position + Vector3(-0.75, 0.0, 0.0))
	var blocked_result: Dictionary = scene.call("perform_player_attack_for_test", Vector2.RIGHT)
	_expect(not bool(blocked_result.get("accepted", true)), "immediate second attack should be rejected by cooldown")

	scene.queue_free()
	await process_frame
	_finish()

func _mouse_click() -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	return event

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_PROTOTYPE_2_5D_PLAYER_ATTACK_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
