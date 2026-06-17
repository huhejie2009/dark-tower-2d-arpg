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

	_expect(scene.has_method("build_animation_state_snapshot_for_test"), "prototype should expose animation state sync snapshot")
	_expect(scene.has_method("set_player_move_input_for_test"), "prototype should expose deterministic movement")
	_expect(scene.has_method("set_player_position_for_test"), "prototype should expose deterministic player positioning")
	_expect(scene.has_method("get_enemy_screen_position_for_test"), "prototype should expose enemy screen position")
	if not scene.has_method("build_animation_state_snapshot_for_test") or not scene.has_method("set_player_move_input_for_test") or not scene.has_method("set_player_position_for_test") or not scene.has_method("get_enemy_screen_position_for_test"):
		scene.queue_free()
		await process_frame
		_finish()
		return

	var initial: Dictionary = scene.call("build_animation_state_snapshot_for_test")
	_expect(str(initial.get("player_animation", "")) == "idle", "player should begin in idle animation")
	_expect(Array(initial.get("enemy_animations", [])).size() == 2, "snapshot should include both enemy animation states")
	_expect(bool(initial.get("player_body_weapon_separated", false)), "player body and weapon animation layers should remain separated")

	scene.call("set_player_move_input_for_test", Vector2.RIGHT)
	await physics_frame
	var moving: Dictionary = scene.call("build_animation_state_snapshot_for_test")
	_expect(str(moving.get("player_animation", "")) == "run", "movement should sync player billboard animation to run")
	_expect(str(moving.get("player_facing_direction", "")) == "right", "movement should sync player facing direction")

	var enemy_loop: Dictionary = scene.call("build_enemy_loop_snapshot_for_test")
	var enemy_states: Array = Array(enemy_loop.get("enemy_states", []))
	_expect(enemy_states.size() == 2, "enemy loop should expose two enemies")
	if enemy_states.is_empty():
		scene.queue_free()
		await process_frame
		_finish()
		return

	var first_enemy_position: Vector3 = Dictionary(enemy_states[0]).get("position", Vector3.ZERO)
	scene.call("set_player_position_for_test", first_enemy_position + Vector3(-0.75, 0.0, 0.0))
	scene.call("clear_player_move_input_override_for_test")
	scene.call("clear_player_attack_direction_override_for_test")
	await process_frame
	await physics_frame

	scene.call("_input", _mouse_click(scene.call("get_enemy_screen_position_for_test", 0)))
	await physics_frame
	var attacking: Dictionary = scene.call("build_animation_state_snapshot_for_test")
	_expect(str(attacking.get("player_animation", "")) == "attack", "accepted attack should sync player billboard animation to attack")
	_expect(int(attacking.get("player_frame_index", -1)) >= 8, "attack animation should use attack frame range")

	for _index in range(40):
		await physics_frame
	var settled: Dictionary = scene.call("build_animation_state_snapshot_for_test")
	_expect(str(settled.get("player_animation", "")) != "attack", "player animation should leave attack after cooldown")

	scene.call("defeat_enemy_for_test", 1)
	await physics_frame
	var death: Dictionary = scene.call("build_animation_state_snapshot_for_test")
	var enemy_animations: Array = Array(death.get("enemy_animations", []))
	_expect(enemy_animations.size() >= 2, "death snapshot should still include both enemies")
	if enemy_animations.size() >= 2:
		var defeated_enemy: Dictionary = Dictionary(enemy_animations[1])
		_expect(str(defeated_enemy.get("animation", "")) == "death", "defeated enemy should sync billboard animation to death")
		_expect(bool(defeated_enemy.get("animation_locked_until_end", false)), "defeated enemy death animation should lock until end")

	scene.queue_free()
	await process_frame
	_finish()

func _mouse_click(position: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = position
	return event

func _finish() -> void:
	if failures.is_empty():
		print("NEW_PROJECT_PROTOTYPE_2_5D_ANIMATION_STATE_SYNC_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
